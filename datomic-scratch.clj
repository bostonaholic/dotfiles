(ns user.datomic-scratch
  (:require '[datomic.api :as d]))

(def url "datomic:mem://scratch")
(d/delete-database url)
(d/create-database url)
(def conn (d/connect url))

(def schema
  [{:db/id (d/tempid :db.part/db)
    :db/ident :user/firstname
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one
    :db/doc "A user's first name"
    :db.install/_attribute :db.part/db}

   {:db/id (d/tempid :db.part/db)
    :db/ident :user/lastname
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one
    :db/doc "A user's last name"
    :db.install/_attribute :db.part/db}])
(d/transact conn schema)

(d/transact conn [{:db/id (d/tempid :db.part/user)
                   :user/firstname "John"
                   :user/lastname "Smith"}])
(d/q '[:find ?id
       :in $
       :where
       [?id :user/firstname ?firstname]
       [?id :user/lastname ?lastname]]
     (d/db conn))
;; => #{[17592186045418 "John" "Smith]}

(d/transact conn [{:db/id 17592186045418
                   :user/firstname "Bob"}])
(d/q '[:find ?id ?firstname ?lastname
       :in $
       :where
       [?id :user/firstname ?firstname]
       [?id :user/lastname ?lastname]]
     (d/db conn))
;; => #{[17592186045418 "Bob" "Smith"]}

(d/transact conn [[:db/retract 17592186045418
                   :user/lastname "Smith" ]])
(d/touch
 (d/entity (d/db conn)
           17592186045418))
;; => {:user/firstname "Bob", :db/id 17592186045418}
