(require '[datomic.api :as d])

(def url "datomic:mem://scratch")
(d/delete-database url)
(d/create-database url)
(def conn (d/connect url))

(def schema
  [{:db/id (d/tempid :db.part/db)
    :db/ident :user/name
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one
    :db/doc "A user's name"
    :db.install/_attribute :db.part/db}])
(d/transact conn schema)

(d/transact conn [{:db/id (d/tempid :db.part/user)
                   :user/name "Joe"}])
(d/q '[:find ?id ?attr ?v
       :in $ ?attr
       :where [?id ?attr ?v]]
     (d/db conn)
     :user/name)
;; => #{[17592186045418 :user/name "Joe"]}

(d/transact conn [{:db/id 17592186045418
                   :user/name "Bob"}])
(d/q '[:find ?id ?attr ?v
       :in $ ?attr
       :where [?id ?attr ?v]]
     (d/db conn)
     :user/name)
;; => #{[17592186045418 :user/name "Bob"]}

(d/transact conn [[:db/retract 17592186045418
                   :user/name "Bob" ]])
(d/q '[:find ?id ?attr ?v
       :in $ ?attr
       :where [?id ?attr ?v]]
     (d/db conn)
     :user/name)
;; => #{}
