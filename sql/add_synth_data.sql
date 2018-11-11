call createUser('Alice'); -- auto inc starts from 1
call createUser('Bob');
call createUser('Metallica');
call createUser('Judas Priest');
call createUser('Iron Maiden');
call createUser('Lesser Known Band');

insert into Follower(subjectID, observerID) values(3, 1);
insert into Follower(subjectID, observerID) values(4, 1);
insert into Follower(subjectID, observerID) values(5, 1);
insert into Follower(subjectID, observerID) values(6, 1);
-- bob follows 3 of the same users alice follows.
insert into Follower(subjectID, observerID) values(3, 2);
insert into Follower(subjectID, observerID) values(4, 2);
insert into Follower(subjectID, observerID) values(5, 2);

insert into Tweet(uID, bodyText) values (1, 'My name is Alice.');
insert into Tweet(uID, bodyText) values (1, 'Good weather today.');
insert into Tweet(uID, bodyText) values (1, 'That last episode of that show was a real thriller');
insert into Tweet(uID, bodyText) values (2, 'Yes, I can Build it.');

insert into LikedTweet(uID, TweetID) values (1, 4); -- alice likes bob's 'Yes, I can Build it.'

 
