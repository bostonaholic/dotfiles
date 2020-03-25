;; ln -s $PWD/profiles.clj ~/.lein/profiles.clj
{:user {:plugins [[atroche/lein-ns-dep-graph "0.2.0-SNAPSHOT"]
                  [cider/cider-nrepl "0.24.0"]
                  [lein-ancient "0.6.15"]]
        :dependencies [[org.clojure/tools.nrepl "0.2.13"]
                       [nrepl "0.6.0"]]
        :injections [(defn hello [name] (println (str "Hello, " name)))
                     (defn spongemock [s] (apply str (map #((rand-nth [clojure.string/upper-case clojure.string/lower-case]) %) s)))
                     (defn median [coll] ;; FIXME: why?
                       (let [sorted (sort coll)
                             halfway (/ (count coll) 2)]
                         (if (odd? (count coll))
                           (nth sorted halfway)
                           (let [a (nth sorted (dec halfway))
                                 b (nth sorted halfway)
                                 average (fn [x y] (/ (+ x y) 2))]
                             (average a b)))))]}}
