#!/usr/bin/env bb

(require '[babashka.process :as pr]
         '[babashka.fs :as fs]
         '[clojure.string :as str]
         '[clojure.pprint :refer [pprint]])

(def mountpoint->device
  (->> (pr/shell {:out :string} "mount")
       :out
       str/split-lines
       (map (fn [line] (let [m (re-matches #"^(/dev/[^ ]+) on ([^ ]+).*" line)]
                         (when m
                           [(nth m 2) (nth m 1)]))))
       (remove nil?)
       (into {})
      ))

(def device->uuid
  (->> (pr/shell {:out :string} "blkid")
       :out
       str/split-lines
       (map (fn [line] (let [m (re-matches #"^(/dev/[^:]+):.* UUID=\"(.*?)\".*" line)]
                         (when m
                           [(nth m 1) (nth m 2)]))))
       (remove nil?)
       (into {})
       ))

(defn get-mountpoint-uuid [mountpoint]
  (->> mountpoint
       mountpoint->device
       device->uuid
       ))

(defn edit-file
  "Edit a file, replacing patt1 with patt2."
  [fname patt1 patt2]
  (let [fname (str fname)]
    (println (format "** edit file %s: replace \"%s\" with \"%s\"" fname patt1 patt2))
    (spit fname (str/replace (slurp fname) patt1 patt2))))

;; (clojure.string/replace
;;  (slurp "/boot/efi/EFI/ubuntu-test/grub.cfg")
;;  "6690"
;;  "XXXX" )

(defn help-message []
  (prn "Usage:  make-btrfs.clj <ext4-mountpoint> <btrfs-mountpoint> <entryname>")
  (System/exit 1))

(defn copy-to-subvolume [ext4-mountpoint btrfs-mountpoint]
  (doseq [cmd [(format "btrfs subvolume create %s/@" btrfs-mountpoint)
               (format "rsync -a -A %s/ %s/@" ext4-mountpoint btrfs-mountpoint)
               (format "btrfs subvolume set-default %s/@" btrfs-mountpoint)]]
    (println "+" cmd)
    (pr/shell cmd)))

(defn add-to-bootmenu [boot-entry]
  (let [efi-dirname (str/replace boot-entry #" " "-")
        cmd (format "efibootmgr -c -d /dev/nvme0n1 -p 1 -L '%s' -l \\EFI\\%s\\shimx64.efi"
                    boot-entry
                    efi-dirname)]
    (println "+" cmd)
    (pr/shell cmd)
    ))

(defn create-efi-entry [boot-entry ext4-uuid btrfs-uuid]
  (let [efi-dirname (str/replace boot-entry #" " "-")
        efi-dirpath (str "/boot/efi/EFI/" efi-dirname)
        efi-grubcfg (str efi-dirpath "/grub.cfg")
        cmd (str "rsync -av /boot/efi/EFI/ubuntu/ " efi-dirpath)]
    (println "+" cmd)
    (pr/shell cmd)
    (edit-file efi-grubcfg ext4-uuid btrfs-uuid)
    ))

(defn verify-partition-uuids [ext4fs btrfs]
  (let [ext4-uuid (get-mountpoint-uuid ext4fs)
        btrfs-uuid (get-mountpoint-uuid btrfs)]
    (when (not ext4-uuid)
      (str "Cannot find UUID for" ext4fs))
    (when (not btrfs-uuid)
      (str "Cannot find UUID for" btrfs-uuid))
    ))

(defn update-efi-uuid [boot-entry ext4fs btrfs]
  (let [ext4-uuid (get-mountpoint-uuid ext4fs)
        btrfs-uuid (get-mountpoint-uuid btrfs)
        _efi-dirname (str/replace boot-entry #" " "-")]
    (println "ext4-uuid:" ext4-uuid)
    (println "btrfs-uuid:" btrfs-uuid)
    ))

(defn fix-grub-cfg [btrfs ext4-uuid btrfs-uuid]
  (let [btrfs-boot-grubcfg (str btrfs "/@/boot/grub/grub.cfg")]
    (edit-file btrfs-boot-grubcfg ext4-uuid btrfs-uuid)))

(defn fix-fstab [btrfs ext4-uuid btrfs-uuid]
  (let [btrfs-fstab (str btrfs "/@/etc/fstab")]
    (edit-file btrfs-fstab ext4-uuid btrfs-uuid)
    (edit-file btrfs-fstab "ext4" "btrfs")
    (edit-file btrfs-fstab "btrfs defaults" "btrfs compress=zstd,defaults")
    ))

(defn btrfs-final-adjustments [btrfs-mountpoint]
  (doseq [cmd [(str "btrfs subv set-default " btrfs-mountpoint "/@")
               (str "ln -s @/boot " btrfs-mountpoint "/boot")]]
    (println "+" cmd)
    (pr/shell cmd)))

(defn main []
  (when (not= (count *command-line-args*) 3)
    (help-message))

  (let [[ext4-mountpoint btrfs-mountpoint entryname] *command-line-args*]
    (println  "Converting" ext4-mountpoint "to btrfs in" btrfs-mountpoint)
    (if-let [errmsg (verify-partition-uuids ext4-mountpoint btrfs-mountpoint)]
      (prn errmsg)
      (let [ext4-uuid (get-mountpoint-uuid ext4-mountpoint)
            btrfs-uuid (get-mountpoint-uuid btrfs-mountpoint)]

        (println)
        (println "Create bios boot menu entry")
        (add-to-bootmenu entryname)

        (println)
        (println "Create efi entry for" entryname)
        (create-efi-entry entryname ext4-uuid btrfs-uuid)

        (println)
        (println "Copying data to btrfs subvolume")
        (copy-to-subvolume ext4-mountpoint btrfs-mountpoint)

        (println)
        (println "patching /boot/grub/grub.cfg in btrfs partition")
        (fix-grub-cfg btrfs-mountpoint ext4-uuid btrfs-uuid)

        (println)
        (println "Link /boot, set default subvolume to @")
        (btrfs-final-adjustments btrfs-mountpoint)

        (println)
        (println "patching /etc/fstab in btrfs partition")
        (fix-fstab btrfs-mountpoint ext4-uuid btrfs-uuid)
        ))
    ))

(main)
