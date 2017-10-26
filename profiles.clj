;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-ancient "0.6.12"]
                  [lein-kibit "0.1.5"]]
        :dependencies [[criterium "0.4.4"]
                       [slamhound "1.5.5"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}
        :injections [(defn hello [name] (println (str "Hello, " name)))]}
 :repl {:dependencies [^:displace [org.clojure/clojure "1.9.0-beta3"]
                       [org.clojure/tools.nrepl "0.2.13"]
                       [org.clojure/tools.namespace "0.2.11"]
                       [criterium "0.4.4"]]
        :plugins [[cider/cider-nrepl "0.15.1"]]}}
