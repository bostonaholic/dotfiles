;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[lein-ancient "0.6.10"]
                  [atroche/lein-ns-dep-graph "0.2.0-SNAPSHOT"]
                  [lein-hiera "0.9.5"]
                  [lein-kibit "0.1.5"]
                  [lein-pprint "1.1.2"]]
        :dependencies [[criterium "0.4.4"]
                       [slamhound "1.5.5"]]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}
        :injections [(defn hello [name] (println (str "Hello, " name)))]}
 :repl {:dependencies [^:displace [org.clojure/clojure "1.9.0-alpha14"]
                       [org.clojure/data.csv "0.1.3"]
                       [org.clojure/tools.nrepl "0.2.12"]
                       [org.clojure/tools.namespace "0.2.11"]
                       [com.cemerick/piggieback "0.2.1"]
                       [criterium "0.4.4"]]
        :plugins [[cider/cider-nrepl "0.14.0"]]}}
