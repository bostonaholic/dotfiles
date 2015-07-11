;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[cider/cider-nrepl "0.9.1"]
                  [lein-ancient "0.5.5"]
                  [lein-cloverage "1.0.2"]
                  [lein-kibit "0.1.2"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "0.3.4"]
                  [lein-immutant "1.2.2"]
                  [lein-ns-dep-graph "0.1.0-SNAPSHOT"]
                  [lein-cljsbuild "1.0.4"]
                  [lein-deps-tree "0.1.2"]]
        :dependencies [[org.clojure/tools.nrepl "0.2.10"]
                       [slamhound "1.5.5"]
                       [criterium "0.4.3"]
                       #_[datomic-schema-grapher.core "0.0.1" :exclusions [com.datomic/datomic-free]]
                       [com.datomic/datomic-free "0.9.4956" :exclusions [joda-time]]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
