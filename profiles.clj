;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-kibit "0.0.8"]
                  [lein-pprint "1.1.1"]]
        :dependencies [[slamhound "1.3.3"]
                       [criterium "0.4.1"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
