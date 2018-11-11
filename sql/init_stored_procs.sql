/*
	Advanced query requirements:
	* group by/having	: newFollowSuggestionsForName
	* co-related		: TODO
	* outer join		: TODO
	* set operations	: TODO (unless IN/EXISTS counts)
	* aggregation		: TODO
	
	More reqs:
	There should be relations connect one relation to at least one other relation. The Loan relation in our case study is such an example, that is, Loan connects User and Book.
*/



/*
Ideas for 15 operations:

Five of these must be of a certain complex statement.
One of these should link a table A to C thru a table B.

* Create new user
* Delete user
* User like tweet
* User retweet post
* User follower another
* Unfollow.
* User create post.
* Send a user all posts they’ve liked.
* Send a user list of all their followers.
* If user A and B both follow X, send A a list of all those B follows, if A does not already follow them.
* List most followed users.
* Show a list of posts from any of a user’s followers in order of date.
* View user account info.
* Find avg age of all those who follow a certain user.
* mutual followers/users
*/

DELIMITER //
-- CREATE PROCEDURE createUser(IN in_name CHAR(60), IN in_age INT)
CREATE PROCEDURE createUser(IN in_name CHAR(60))
BEGIN
  -- insert into User(name, age) values(in_name, in_age);
  insert into User(name) values(in_name);
END //
DELIMITER ;


-- not sure about parentID vs retweet now

DELIMITER //
CREATE PROCEDURE createTweet(IN in_uid INT, in_text varchar(500))
BEGIN
  insert into Tweet(uID , bodyText) values(in_uid, in_text);
END //
DELIMITER ;


-- limit?
-- if wanted to scroll through all followers of user,
-- would want a way to return [B:E) ranked elements per page of results.
DELIMITER //
CREATE PROCEDURE showWhoUserNameFollows(IN in_name CHAR(60))
BEGIN

  DECLARE auid INT;
  SET auid = (select uID from User where name=in_name);  

  select name
  from User
  where uID in (select subjectID from Follower where observerID=auid)
  order by name;
END //
DELIMITER ;


-- Shows sorted list of most liked tweets in the past 24 hours,
-- and also joins the authors username.
DELIMITER //
CREATE PROCEDURE show24HourMostLiked()
BEGIN
  select name, timeMade, nLikes, bodyText
  from (select uID, timeMade, nLikes, bodyText from Tweet where TIMESTAMPDIFF(SECOND, now(), timeMade)<86400) as T, User
  where User.uID = T.uID
  order by nLikes DESC;
END //
DELIMITER ;

-- dont select name, would be same as passed in
DELIMITER //
CREATE PROCEDURE showUserInfoAndFollowing(IN in_name CHAR(60), OUT out_nfollowers INT, OUT out_nfollowing INT)
BEGIN
  select nFollowers, nFollowing into out_nfollowers, out_nfollowing
  from User
  where name = in_name;
  call showWhoUserNameFollows(in_name);
END //
DELIMITER ;


-- Need some more advanced queries for project.
-- Heres an idea: Suggest to person A a list of usernames to follow based on the following:
-- If person B follows at least 3 of the same people A follows, suggest people that B follows
-- and A does not already follow.
-- This uses group by/having.

DELIMITER //
CREATE PROCEDURE newFollowSuggestionsForName(IN in_name CHAR(60))
BEGIN

DECLARE auid INT;
SET auid = (select uID from User where name=in_name);  

select name
from User, (select subjectID
			from follower
			where observerID in (
				select observerID
				from Follower
				where observerID<>auid and subjectID in (select subjectID from Follower where observerID=auid)
				group by observerID
				having count(*)>=3
			)
	) as T
where uID = T.subjectID and not exists (select * from Follower where subjectID=T.subjectID and observerID=auid);

END //
DELIMITER ;

/*
mysql> select uID, name from User;
+-----+-------------------+
| uID | name              |
+-----+-------------------+
|   1 | Alice             |
|   2 | Bob               |
|   5 | Iron Maiden       |
|   4 | Judas Priest      |
|   6 | Lesser Known Band |
|   3 | Metallica         |
+-----+-------------------+
6 rows in set (0.00 sec)

mysql> select * from Follower;
+-----------+------------+
| subjectID | observerID |
+-----------+------------+
|         3 |          1 |
|         4 |          1 |
|         5 |          1 |
|         6 |          1 |
|         3 |          2 |
|         4 |          2 |
|         5 |          2 |
+-----------+------------+
7 rows in set (0.00 sec)

mysql> call newFollowSuggestionsForName('Bob');
+-------------------+
| name              |
+-------------------+
| Lesser Known Band |
+-------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

mysql>
*/
