;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-kibit "RELEASE"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "RELEASE"]
                  [lein-immutant "1.2.0"]]
        :dependencies [[slamhound "RELEASE"]
                       [criterium "RELEASE"]
                       [com.datomic/datomic-free "RELEASE"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}

(defn wat
  "prints a listing of all namespaces and count of interns in the repl"
  []
  (->> (all-ns)
       (map #(vector (str %) (count (ns-interns %))))
       sort
       clojure.pprint/pprint))
