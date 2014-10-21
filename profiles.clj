;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [;[cider/cider-nrepl "0.7.0"]
                  ;[org.clojure/tools.nrepl "0.2.3"]
                  [lein-cloverage "1.0.2"]
                  [lein-kibit "0.0.8"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "0.3.4"]
                  [lein-immutant "1.2.2"]
                  [lein-ns-dep-graph "0.1.0-SNAPSHOT"]
                  [lein-cljsbuild "1.0.3"]
                  [com.cemerick/clojurescript.test "0.3.1"]]
        :dependencies [[org.clojure/tools.nrepl "0.2.3"]
                       [slamhound "1.5.5"]
                       [criterium "0.4.3"]
                       #_[datomic-schema-grapher.core "0.0.1" :exclusions [com.datomic/datomic-free]]
                       [com.datomic/datomic-free "0.9.4956" :exclusions [joda-time]]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}

(defn wat
  "prints a listing of all namespaces and count of interns in the repl"
  []
  (->> (all-ns)
       (map #(vector (str %) (count (ns-interns %))))
       sort
       clojure.pprint/pprint))
