;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-kibit "RELEASE"]
                  [lein-pprint "1.1.1"]
                  [lein-exec "RELEASE"]]
        :dependencies [[slamhound "RELEASE"]
                       [criterium "RELEASE"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}}
