;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-kibit "RELEASE"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "RELEASE"]
                  [lein-immutant "1.2.2"]
                  [lein-ns-dep-graph "0.1.0-SNAPSHOT"]
                  [lein-cljsbuild "RELEASE"]
                  [com.cemerick/clojurescript.test "0.3.1"]]
        :dependencies [[slamhound "RELEASE"]
                       [criterium "RELEASE"]
                       #_[datomic-schema-grapher.core "0.0.1" :exclusions [com.datomic/datomic-free]]
                       [com.datomic/datomic-free "RELEASE"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}

(defn wat
  "prints a listing of all namespaces and count of interns in the repl"
  []
  (->> (all-ns)
       (map #(vector (str %) (count (ns-interns %))))
       sort
       clojure.pprint/pprint))
