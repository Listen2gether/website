when defined(js):
  import std/asyncjs
else:
  import
    std/asyncdispatch

import
  std/[times, strutils],
  pkg/listenbrainz,
  pkg/listenbrainz/utils/api,
  pkg/listenbrainz/core,
  ../types

include pkg/listenbrainz/utils/tools

const userBaseUrl* = "https://listenbrainz.org/user/"

proc to*(val: Option[seq[cstring]]): Option[seq[string]] =
  ## Convert `Option[seq[cstring]]` to `Option[seq[string]]`
  if isSome val:
    var list: seq[string]
    for item in val.get():
      list.add $item
    result = some list
  else:
    result = none seq[string]

proc to*(val: Option[seq[string]]): Option[seq[cstring]] =
  ## Convert `Option[seq[string]]` to `Option[seq[cstring]]`
  if isSome val:
    var list: seq[cstring]
    for item in val.get():
      list.add cstring item
    result = some list
  else:
    result = none seq[cstring]

proc to*(val: Option[string]): Option[cstring] =
  ## Convert `Option[string]` to `Option[cstring]`
  if isSome val:
    result = some cstring get val
  else:
    result = none cstring

proc to*(
  track: Track,
  listenedAt: Option[int]): APIListen =
  ## Convert a `Track` object to a `Listen` object
  let
    additionalInfo = AdditionalInfo(tracknumber: track.trackNumber,
                                    trackMbid: some $track.recordingMbid,
                                    recordingMbid: some $track.recordingMbid,
                                    releaseMbid: some $track.releaseMbid,
                                    artistMbids: to track.artistMbids)
    trackMetadata = TrackMetadata(trackName: $track.trackName,
                                  artistName: $track.artistName,
                                  releaseName: some $track.releaseName,
                                  additionalInfo: some additionalInfo)
  result = APIListen(listenedAt: listenedAt,
                     trackMetadata: trackMetadata)

proc to*(
  listen: APIListen,
  preMirror: Option[bool] = none(bool)): Track =
  ## Convert a `Listen` object to a `Track` object
  result = newTrack(trackName = cstring listen.trackMetadata.trackName,
                    artistName = cstring listen.trackMetadata.artistName,
                    releaseName = to listen.trackMetadata.releaseName,
                    recordingMbid = to get(listen.trackMetadata.additionalInfo, AdditionalInfo()).recordingMbid,
                    releaseMbid = to get(listen.trackMetadata.additionalInfo, AdditionalInfo()).releaseMbid,
                    artistMbids = to get(listen.trackMetadata.additionalInfo, AdditionalInfo()).artistMbids,
                    trackNumber = get(listen.trackMetadata.additionalInfo, AdditionalInfo()).trackNumber,
                    listenedAt = listen.listenedAt,
                    preMirror = preMirror,
                    mirrored = some false)

proc to*(
  listens: seq[APIListen],
  preMirror: Option[bool] = none(bool)): seq[Track] =
  ## Convert a sequence of `Listen` objects to a sequence of `Track` objects
  for listen in listens:
    result.add to(listen, preMirror)

proc to*(
  userListens: UserListens,
  listenType: ListenType): SubmitListens =
  ## Convert a `UserListens` object to a `SubmitListens` object
  result = SubmitListens(listenType: listenType, payload: userListens.payload.listens)

proc getNowPlaying*(
  lb: AsyncListenBrainz,
  username: cstring): Future[Option[Track]] {.async.} =
  ## Return a ListenBrainz user's now playing
  let
    nowPlaying = await lb.getUserPlayingNow($username)
    payload = nowPlaying.payload
  if payload.count == 1:
    result = some(to(payload.listens[0]))
  else:
    result = none(Track)

proc getRecentTracks*(
  lb: AsyncListenBrainz,
  username: cstring,
  preMirror: bool,
  maxTs, minTs: int = 0): Future[seq[Track]] {.async.} =
  ## Return a ListenBrainz user's listen history
  let userListens = await lb.getUserListens($username, maxTs = maxTs, minTs = minTs)
  result = to(userListens.payload.listens, some preMirror)

proc initUser*(
  lb: AsyncListenBrainz,
  username: cstring,
  token: cstring = ""): Future[User] {.async.} =
  ## Gets a given user's now playing, recent tracks, and latest listen timestamp.
  ## Returns a `User` object
  let userId = cstring($Service.listenBrainzService & ":" & $username)
  var user = newUser(userId = userId, services = [Service.listenBrainzService: newServiceUser(Service.listenBrainzService, username = username, token = token), Service.lastFmService: newServiceUser(Service.lastFmService)])
  user.lastUpdateTs = int toUnix getTime()
  user.playingNow = await lb.getNowPlaying(username)
  user.listenHistory = await lb.getRecentTracks(username, preMirror = true)
  return user

proc updateUser*(
  lb: AsyncListenBrainz,
  user: User,
  preMirror = true): Future[User] {.async.} =
  ## Updates user's now playing, recent tracks, and latest listen timestamp
  var updatedUser = user
  updatedUser.lastUpdateTs = int toUnix getTime()
  updatedUser.playingNow = await lb.getNowPlaying(user.services[listenBrainzService].username)
  let newTracks = await lb.getRecentTracks(user.services[listenBrainzService].username, preMirror, minTs = user.lastUpdateTs)
  updatedUser.listenHistory = newTracks & user.listenHistory
  return updatedUser

proc pageUser*(
  lb: AsyncListenBrainz,
  user: var User) {.async.} =
  ## Backfills user's recent tracks
  let maxTs = get user.listenHistory[^1].listenedAt
  let newTracks = await lb.getRecentTracks(user.services[listenBrainzService].username, preMirror = true, maxTs = maxTs)
  user.listenHistory = user.listenHistory & newTracks

# index history by listenedAt
# on init: get now playing and history set tracks as premirror
# on update: get listens, add to history if greater than lastUpdateTs, set as mirrored only when submitted succesfully

# def submitMirrorQueue*
