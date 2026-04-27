#!/usr/bin/env bb

(require '[babashka.process :as pr]
         '[babashka.fs :as :fs]
         '[clojure.string :as str]
         '[clojure.java.io :as io]
         )

(defn write-checksums
  [checksums fname]
  (with-open [w (io/writer fname)]
    (doseq [line checksums]
      (.write w (str (pr-str line) "\n"))
      )))

(defn read-checksums
  [fname]
  (with-open [r (io/reader fname)]
    (->> (reduce conj [] (line-seq r))
         (map read-string))))

(defn compute-checksum
  [fname]
  (->> (pr/shell {:out :string} "md5sum" fname)
       :out
       str/split-lines
       first
       (#(str/split % #" +" 2))
       ))

(defn find-files
  []
  (->> (fs/glob "." "**")
       (map str)
       (filter (complement #(str/starts-with? % "repos")))
       (filter (complement #(str/starts-with? % "synced")))
       (filter (complement #(str/starts-with? % "EncDocs")))
       (filter (complement #(str/starts-with? % "Private")))
       (filter (complement #(str/starts-with? % "Dropbox/finance")))
       (filter (complement #(str/starts-with? % "Dropbox/Jobs/Synthego")))
       ;; (filter (complement #(str/starts-with? % "refile/samples/facebook")))
       (filter fs/regular-file?)
       (sort)
       ))

(defn checksums-to-map
  [checksums]
  (into {} (map #(vector (second %) (first %)) checksums)))

(defn update-checksums
  [fname]
  (let [filenames (find-files)
        current-checksums (read-checksums fname)
        fname->checksum (checksums-to-map current-checksums)
        new-files (filter #(nil? (fname->checksum %)) filenames)
        new-checksum-map (->> (pmap compute-checksum new-files)
                              (checksums-to-map))
        update-file-checksum (fn [fname]
                               (if-let [checksum (fname->checksum fname)]
                                 [checksum fname]
                                 [(new-checksum-map fname) fname]))

        new-checksums (map update-file-checksum filenames)]
    (write-checksums new-checksums fname)
    ))

(defn generate-checksums
  [fname]
  (let [filenames (find-files)
        checksums (pmap compute-checksum filenames)]
    (write-checksums checksums fname)
))

(defn find-dups
  []
  (let [checksums (read-checksums "/tmp/checksums")
        dups (->> checksums
                  (sort)
                  (partition-by first)
                  (filter #(> (count %) 2))
                  (apply concat)
                  )]
    (write-checksums dups "/tmp/duplicates")))

(update-checksums "/tmp/checksums")
(find-dups)
