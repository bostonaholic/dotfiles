;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-kibit "0.0.8"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "0.3.1"]]
        :dependencies [[slamhound "1.5.0"]
                       [criterium "0.4.2"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
