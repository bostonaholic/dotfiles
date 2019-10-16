;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:pedantic? :ranges
        :plugins [[atroche/lein-ns-dep-graph "0.2.0-SNAPSHOT"]
                  [cider/cider-nrepl "0.22.3"]
                  [lein-ancient "0.6.15"]
                  [lein-kibit "0.1.6"]
                  [lein-nsorg "0.2.0"]]
        :dependencies [[slamhound "1.5.5"]
                       [org.clojure/tools.nrepl "0.2.13"]
                       [nrepl "0.6.0"]]
        :injections [(defn hello [name] (println (str "Hello, " name)))
                     (defn median [coll]
                     (defn spongemock [s] (apply str (map #((rand-nth [clojure.string/upper-case clojure.string/lower-case]) %) s)))
                       (let [sorted (sort coll)
                             halfway (/ (count coll) 2)]
                         (if (odd? (count coll))
                           (nth sorted halfway)
                           (let [a (nth sorted (dec halfway))
                                 b (nth sorted halfway)
                                 average (fn [x y] (/ (+ x y) 2))]
                             (average a b)))))]
        :aliases {"slamhound" ["run" "-m" "slam.hound"]}}
 :repl {:dependencies [#_^:displace [org.clojure/clojure "1.10.0"]
                       [cheshire "5.8.0"]
                       [criterium "0.4.4"]
                       [org.clojure/tools.nrepl "0.2.13"]]
        :injections [(require '[cheshire.core :as json])]}}
