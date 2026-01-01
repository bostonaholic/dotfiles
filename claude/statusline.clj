#!/usr/bin/env bb
;; Status line for Claude Code - Clojure/Babashka implementation
;;
;; Example output:
;;   📁 dotfiles 🌿 (main*↑2) 🧠 [████░░░░░░ 35%] 💰 $0.1234 ⚡ Opus 4.5
;;
;; Usage:
;;   echo '{"workspace":...}' | ./statusline.clj

(ns statusline
  (:require [babashka.process :as p]
            [cheshire.core :as json]
            [clojure.string :as str]))

;; ANSI Colors
(def colors
  {:reset   "\033[0m"
   :red     "\033[31m"
   :yellow  "\033[33m"
   :cyan    "\033[36m"
   :magenta "\033[35m"
   :gray    "\033[90m"
   :white   "\033[37m"})

(defn colorize [color text]
  (str (colors color) text (:reset colors)))

;; Git helpers
(defn sh
  "Run shell command, return trimmed stdout or nil on failure."
  [& args]
  (let [result (apply p/shell {:out :string :err :string :continue true} args)]
    (when (zero? (:exit result))
      (str/trim (:out result)))))

(defn git-repo? [cwd]
  (some? (sh "git" "-C" cwd "rev-parse" "--git-dir")))

(defn get-git-info [cwd]
  (when (git-repo? cwd)
    (let [root (sh "git" "-C" cwd "rev-parse" "--show-toplevel")
          branch (or (sh "git" "-C" cwd "symbolic-ref" "--short" "HEAD") "detached")
          dirty? (or (not (sh "git" "-C" cwd "diff" "--quiet"))
                     (not (sh "git" "-C" cwd "diff" "--cached" "--quiet")))
          ahead-output (sh "git" "-C" cwd "rev-list" "@{u}..HEAD")
          ahead (if ahead-output
                  (count (str/split-lines ahead-output))
                  0)]
      {:root root
       :name (when root (last (str/split root #"/")))
       :branch branch
       :dirty? dirty?
       :ahead ahead})))

;; Formatting functions
(defn format-directory [{:keys [workspace git]}]
  (let [cwd (:current_dir workspace)
        home (System/getenv "HOME")
        dir-name (cond
                   (= cwd home) "~"

                   (:root git)
                   (let [rel-path (subs cwd (count (:root git)))]
                     (if (empty? rel-path)
                       (:name git)
                       (str (:name git) rel-path)))

                   :else
                   (let [parts (str/split cwd #"/")]
                     (str/join "/" (take-last 2 parts))))]
    (str "📁 " (colorize :cyan dir-name))))

(defn format-git-info [{:keys [git]}]
  (when git
    (let [{:keys [branch dirty? ahead]} git
          dirty-marker (when dirty? "*")
          ahead-marker (when (pos? ahead) (str "↑" ahead))]
      (str " 🌿 "
           (colorize :gray "(")
           (colorize :yellow (str branch dirty-marker ahead-marker))
           (colorize :gray ")")))))

(defn format-context [{:keys [context_window]}]
  (let [ctx-size (:context_window_size context_window 0)
        usage (:current_usage context_window)]
    (when (and usage (pos? ctx-size))
      (let [input-tokens (:input_tokens usage 0)
            cache-creation (:cache_creation_input_tokens usage 0)
            cache-read (:cache_read_input_tokens usage 0)
            tokens (+ input-tokens cache-creation cache-read)
            pct (quot (* tokens 100) ctx-size)
            filled (quot pct 10)
            empty (- 10 filled)
            bar (apply str (concat (repeat filled "█") (repeat empty "░")))
            color (cond
                    (> pct 70) :red
                    (> pct 40) :yellow
                    :else :white)]
        (str " 🧠 " (colorize color (str "[" bar " " pct "%]")))))))

(defn format-cost [{:keys [context_window]}]
  (when-let [cost (:total_cost_usd context_window)]
    (when (number? cost)
      (str " 💰 " (colorize :yellow (format "$%.4f" cost))))))

(defn format-style [{:keys [output_style]}]
  (let [style (:name output_style)]
    (when (and style (not= style "default"))
      (str " 🎨 " (colorize :cyan (str "[" style "]"))))))

(defn format-model [{:keys [model]}]
  (let [name (or (:display_name model) "unknown")]
    (str " ⚡ " (colorize :magenta name))))

(defn format-status-line [data]
  (str (format-directory data)
       (format-git-info data)
       (format-context data)
       (format-cost data)
       (format-style data)
       (format-model data)))

;; Main
(defn run [input]
  (let [data (json/parse-string input true)
        cwd (get-in data [:workspace :current_dir])
        git-info (when cwd (get-git-info cwd))]
    (println (format-status-line (assoc data :git git-info)))))

(defn -main [& _args]
  (-> *in* slurp run))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
