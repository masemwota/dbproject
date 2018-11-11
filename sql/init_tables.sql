/*
	"There should be relations connect one relation to at least one other relation. The Loan relation in our case study is such an example, that is, Loan connects User and Book."
*/


/*
User(uID, struct{userInfo}, nFollowing, nFollowers);
Tweet(tweetID, uID, message, time, retweets, likes);
LikedTweet(uID , tweetID);
Follow(userA, userB);
Retweet(uID , tweetID, quoteTweet, time);


NEED space after double hyphen for comment.
*/

-- on delete cascade?
-- doing many of some of these operations from scratch seems would be very slow.


DROP DATABASE if exists Twitter;
CREATE DATABASE Twitter;
use Twitter

-- __TABLES__

CREATE TABLE User
(
	uID INT PRIMARY KEY AUTO_INCREMENT,
	name CHAR(60) NOT NULL UNIQUE,
	-- age INT,
	accountCreatedOn DATETIME NOT NULL DEFAULT now(),
	nFollowers INT NOT NULL DEFAULT 0,
	nFollowing INT NOT NULL DEFAULT 0,

	-- an end user will request to follow someone by username, so must be unique.
	-- real name not stored, perhaps should rename name to accountName.	
	UNIQUE(name)
);

CREATE TABLE Tweet
(
	tweetID INT PRIMARY KEY AUTO_INCREMENT,
	uID INT, -- foreign
	bodyText VARCHAR(500),
	parentTweetID INT, -- if NULL, is root of comment chain
	timeMade DATETIME NOT NULL DEFAULT now(),
	nLikes INT NOT NULL DEFAULT 0,
	
	FOREIGN KEY(uID) REFERENCES User(uID)
);

CREATE TABLE LikedTweet
(
	uID INT NOT NULL,
	tweetID INT NOT NULL,
	
	PRIMARY KEY(uID , tweetID),
	FOREIGN KEY(uID) REFERENCES User(uID),
	FOREIGN KEY(tweetID) REFERENCES Tweet(tweetID)
);
 
CREATE TABLE Follower
(
	subjectID INT NOT NULL,
	observerID INT NOT NULL,
	
	PRIMARY KEY(subjectID, observerID),
	FOREIGN KEY(subjectID) REFERENCES User(uID),
	FOREIGN KEY(observerID) REFERENCES User(uID),
	
	CHECK(subjectID<>observerID)
);

CREATE TABLE Retweet
(
	uID INT NOT NULL,
	tweetID INT NOT NULL,
	quoteTweet VARCHAR(250),
	timeMade DATETIME NOT NULL DEFAULT now(),
	
	-- a user can only retweet same tweet once, so this pair uniquely identifies
	PRIMARY KEY(uID, tweetID),
	FOREIGN KEY(uID) REFERENCES User(uID),
	FOREIGN KEY(tweetID) REFERENCES Tweet(tweetID)
);

-- __TRIGGERS__

CREATE TRIGGER LikedTweetIncTrigger
	BEFORE INSERT ON LikedTweet
	FOR EACH ROW
	UPDATE Tweet set nLikes=nLikes+1 where Tweet.tweetID=new.tweetID;

	
DELIMITER $$
CREATE TRIGGER NewFollowIncTrigger
    BEFORE INSERT ON Follower
    FOR EACH ROW 
BEGIN
	UPDATE User set nFollowers=nFollowers+1 where uID=new.subjectID;
	UPDATE User set nFollowing=nFollowing+1 where uID=new.observerID;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER DeleteFollowDecTrigger
    AFTER DELETE ON Follower
    FOR EACH ROW 
BEGIN
	UPDATE User set nFollowers=nFollowers-1 where uID=old.subjectID;
	UPDATE User set nFollowing=nFollowing-1 where uID=old.observerID;
END$$
DELIMITER ;
