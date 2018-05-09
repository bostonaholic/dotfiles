;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:pedantic? :ranges
        :plugins [[lein-ancient "0.6.15"]
                  [lein-kibit "0.1.5"]
                  [atroche/lein-ns-dep-graph "0.2.0-SNAPSHOT"]
                  [lein-nsorg "0.1.3"]]
        :dependencies [[jonase/eastwood "0.2.5"]
                       [pjstadig/humane-test-output "0.8.3"]
                       [slamhound "1.5.5"]]
        :injections [(defn hello [name] (println (str "Hello, " name)))

                     (require 'pjstadig.humane-test-output)
                     (pjstadig.humane-test-output/activate!)]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}
 :repl {:plugins [[cider/cider-nrepl "0.17.0"]]
        :dependencies [#_^:displace [org.clojure/clojure "pp1.9.0"]
                       [criterium "0.4.4"]
                       [cheshire "5.8.0"]
                       [org.clojure/tools.nrepl "0.2.13"]]
        :injections [(require '[cheshire.core :as json])]}}
