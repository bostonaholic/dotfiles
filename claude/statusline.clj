#!/usr/bin/env bb
;; Status line for Claude Code - Clojure/Babashka implementation
;;
;; Example output:
;;   📁 dotfiles 🌿 (main *↑2) 🧠 [████░░░░░░ 35%] 💰 $0.1234 ⚡ Opus 4.5
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

(defn get-model-name [data] (get-in data [:model :display_name] "unknown"))
(defn get-current-dir [data] (get-in data [:workspace :current_dir]))
(defn get-project-dir [data] (get-in data [:workspace :project_dir]))
(defn get-version [data] (:version data))
(defn get-cost [data] (get-in data [:context_window :total_cost_usd]))
(defn get-duration [data] (get-in data [:cost :total_duration_ms]))
(defn get-lines-added [data] (get-in data [:cost :total_lines_added]))
(defn get-lines-removed [data] (get-in data [:cost :total_lines_removed]))
(defn get-input-tokens [data] (get-in data [:context_window :total_input_tokens]))
(defn get-output-tokens [data] (get-in data [:context_window :total_output_tokens]))
(defn get-context-window-size [data] (get-in data [:context_window :context_window_size] 0))
(defn get-output-style [data] (get-in data [:output_style :name] ""))
(defn get-current-usage [data] (get-in data [:context_window :current_usage] {}))

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
(defn format-directory [{:keys [git] :as data}]
  (let [cwd (get-current-dir data)
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
           (colorize :yellow (str branch " " dirty-marker ahead-marker))
           (colorize :gray ")")))))

(defn format-context [data]
  (let [ctx-size (get-context-window-size data)]
    (when (pos? ctx-size)
      (let [usage (get-current-usage data)
            input-tokens (:input_tokens usage 0)
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

(defn format-cost [data]
  (when-let [cost (get-cost data)]
    (when (number? cost)
      (str " 💰 " (colorize :yellow (format "$%.4f" cost))))))

(defn format-style [data]
  (let [style (get-output-style data)]
    (when (and (seq style) (not= style "default"))
      (str " 🎨 " (colorize :cyan (str "[" style "]"))))))

(defn format-model [data]
  (str " ⚡ " (colorize :magenta (get-model-name data))))

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
        cwd (get-current-dir data)
        git-info (when cwd (get-git-info cwd))]
    (println (format-status-line (assoc data :git git-info)))))

(defn -main [& _args]
  (-> *in* slurp run))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
