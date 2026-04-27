#!/usr/bin/env bb

(require '[babashka.process :as pr]
         '[babashka.fs :as :fs]
         '[clojure.string :as str])

(defn compute-checksum
  [fname]
  (->> (pr/shell {:out :string} "md5sum" fname)
       :out
       str/split-lines
       first
       (#(str/split % #" +" 2))
       ))

;; (compute-checksum "cleanup.sh")

(defn find-files
  []
  (->> (fs/glob "." "**")
       (map str)
       (filter (complement #(str/starts-with? % "repos")))
       (filter (complement #(str/starts-with? % "synced")))
       (filter (complement #(str/starts-with? % "EncDocs")))
       (filter (complement #(str/starts-with? % "Private")))
       (filter (complement #(str/starts-with? % "Dropbox/finance")))
       (filter fs/regular-file?)
       (sort)
       ))

;; (find-files)
;; (map compute-checksum)
(defn write-checksums
  [checksum-fname]
  (let [filenames (find-files)
        checksums (pmap compute-checksum filenames)]
    (with-open [w (clojure.java.io/writer checksum-fname)]
      (doseq [line checksums]
        (.write w (str (pr-str line) "\n"))
        ))))

(time (write-checksums "/tmp/checksums"))
