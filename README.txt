 -*- Project Requirement checklist -*-

Advanced query requirements (I belive these can also count as one of 15 operations):

* group by/having	: newFollowSuggestionsForName (jonathan)
* co-related		: TODO
* outer join		: TODO
* set operations	: TODO (unless IN/EXISTS counts)
* aggregation		: TODO

15 operations:

1. showUserInfoAndFollowing (jonathan)
2. newFollowSuggestionsForName (jonathan)
3. show24HourMostLiked (jonathan)
4. createUser (jonathan) // trivial
5. createTweeet (jonathan) // trivial
6.
7.
8.
9.
10.
11.
12.
13.
14.
15.

Triggers:

* There are 3 already for ensuring integrity/validity related to insert queries for User, Follower, and Tweet.
TODO: Triggers on delete, and perhaps more insert/update.

Other:
There should be relations connect one relation to at least one other relation. The Loan relation in our case study is such an example, that is, Loan connects User and Book.

Archiving:
TODO
