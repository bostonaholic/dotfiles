;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[cider/cider-nrepl "0.9.1"]
                  [lein-ancient "0.6.8"]
                  [lein-kibit "0.1.2"]
                  [lein-pprint "1.1.2"]]
        :dependencies [[com.datomic/datomic-free "0.9.5206" :exclusions [joda-time]]
                       [org.clojure/tools.nrepl "0.2.12"]
                       [slamhound "1.5.5"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
