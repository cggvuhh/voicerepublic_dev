(ns vrng.venues.talkbar
  (:require
   [vrng.venues.state :as state :refer [page-state]]
   [vrng.venues.helpers :as helpers :refer [active-talk onair? next-talk venue listener-count format-countdown active-talk-runtime time-to-active-talk time-to-next-talk new-talk-path toggle-talkbar-action talk-list]]
   [vrng.helpers :refer [icon]]
   ))

(defn- get-date-label
  "overwrites label with TODAY for talks scheduled today"
  [date]
  (if (.isSame date (js/moment) "day")
    "TODAY"
    (.format date "DD-MM-YYYY")))

(defn- get-start-date
  "extacts start_at from talk and applies format DD-MM-YYYY"
  [talk]
  (get-date-label (new js/moment (:starts_at talk)) ))

(defn- group-talks-by-date
  "returns a map with dates as keys and talks as values"
  [talks]
  (reduce (fn [acc talk]
            (update acc (-> talk get-start-date keyword) conj talk)) {} talks))

(defn- talk-item-comp
  "returns a talk row component"
  [talk]
  ^{:key (:id talk)}
  [:div.small-12.columns.talkitem.clearfix
   [:p.clearfix
    [:span.title.float-left.text-left
     [:a {:href (:url talk)
          :target "_blank"}
      (:title talk)]]
    [:span.time.float-left.text-left (:starts_at_time talk)]
    [:span.series.float-left.text-left
     [:a {:href (:url (:series talk))} (:title (:series talk))]]
    [:span.duration.float-left.text-right (:duration talk)]]])

(defn- day-comp
  "returns a day row component containing talks"
  [date talks]
  ^{:key date}
  [:div#listrow.row.clearfix
    [:div.small-12.columns.dayitem.clearfix [:p [:span (name date)]]]
    [:div.small-12.columns.headeritem.clearfix
     [:p
      [:span "TITLE"]
      [:span "TIME"]
      [:span "SERIES"]
      [:span.text-right "DURATION"]]]
    (doall (map talk-item-comp talks))])

(defn talkbar-comp
  "the current/next and the dropdown with all scheduled and past talks"
  []
  [:div#talkbar
   {:style {:height (if (@page-state :talkbar-expanded) "auto" "36px")}}
   ;;current
   [:div#current
    (if (active-talk)
      [:p#current-talk-title
       [:span.next-talk "Now: "]
       [:a {:href (:url (active-talk))} (:title (active-talk))]
       (if (onair?)
         [:span.listener-info {:title "listeners"}
          [icon "person"] " " (listener-count)])
       [:span.float-right.time-info (format-countdown
                                     (if (onair?)
                                       (active-talk-runtime)
                                       (time-to-active-talk)))]])]
   (if (next-talk)
     [:div#next
      [:span.next-talk "Next: "]
      [:a {:href (:url (next-talk))} (:title (next-talk))]
      [:span.float-right.time-info (format-countdown (time-to-next-talk))]]
     ;;)
     [:div#next
      [:a {:href (new-talk-path)} "+ Schedule Live Stream"]])

   ;;dropdown
   [:div#list-toggle
    [:a.float-left.hide-for-small-only
     {:href "#" :on-click toggle-talkbar-action}
     [:span.show-for-medium.float-left "ALL TALKS"]
     [icon "list"]]
    [:a.see-all.show-for-small-only.text-center "view all"]]
   (map (partial apply day-comp) (group-talks-by-date (talk-list ["live" "prelive"] [:starts_at <])))])

