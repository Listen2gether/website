when defined(js):
  import pkg/jsutils
import std/options

type
  Session* = ref object
    ## Stores session state, including a `seq` of user IDs, and optionally a mirror user ID.
    id*: cstring
    users*: seq[cstring]
    mirror*: Option[cstring]

  Service* = enum
    ## Stores the service that the user belongs to:
    ##  - `listenBrainzService`: user of the ListenBrainz service
    ##  - `lastFmService`: user of the Last.FM service
    listenBrainzService = "listenbrainz",
    lastFmService = "lastfm"

  User* = ref object
    ## Stores the user information including the api keys for the service it belongs to.
    ##  - `lastUpdateTs`: stores the last listen timestamp.
    id*, username*: cstring
    case service*: Service
    of listenBrainzService:
      token*: cstring
    of lastFmService:
      sessionKey*: cstring
    lastUpdateTs*: int
    playingNow*: Option[Listen]
    listenHistory*: seq[Listen]

  Listen* = object
    ## A normalised listen object.
    ##  - `mirrored`: stores the state of whether a listen to be mirrored has been submitted.
    ##  - `preMirror`: stores the state of whether a listen was submitted within a mirroring session.
    trackName*, artistName*: cstring
    releaseName*, recordingMbid*, releaseMbid*: Option[cstring]
    artistMbids*: Option[seq[cstring]]
    trackNumber*, listenedAt*: Option[int]
    mirrored*, preMirror*: Option[bool]

func newSession*(
  id: cstring = "session",
  users: seq[cstring] = @[],
  mirror: Option[cstring] = none(cstring)): Session =
  result = Session()
  result.id = id
  result.users = users
  result.mirror = mirror

func genId*(username: cstring, service: Service): cstring =
  when defined(js):
    return cstring($service) & ":" & username
  else:
    return cstring($service & ":" & $username)

func newUser*(
  username: cstring,
  service: Service,
  token, sessionKey: cstring = "",
  lastUpdateTs: int = 0,
  playingNow: Option[Listen] = none(Listen),
  listenHistory: seq[Listen] = @[]): User =
  ## Create new User object
  result = User(service: service)
  result.id = genId(username, service)
  result.username = username
  case service:
  of listenBrainzService:
    result.token = token
  of lastFmService:
    result.sessionKey = sessionKey
  result.lastUpdateTs = lastUpdateTs
  result.playingNow = playingNow
  result.listenHistory = listenHistory

func `==`*(a, b: User): bool = a.id == b.id

func newListen*(
  trackName, artistName: cstring,
  releaseName, recordingMbid, releaseMbid: Option[cstring] = none(cstring),
  artistMbids: Option[seq[cstring]] = none(seq[cstring]),
  trackNumber: Option[int] = none(int),
  listenedAt: Option[int] = none(int),
  mirrored, preMirror: Option[bool] = none(bool)): Listen =
  ## Create new Listen object
  result.trackName = trackName
  result.artistName = artistName
  result.releaseName = releaseName
  result.recordingMbid = recordingMbid
  result.releaseMbid = releaseMbid
  result.artistMbids = artistMbids
  result.trackNumber = trackNumber
  result.listenedAt = listenedAt
  result.mirrored = mirrored
  result.preMirror = preMirror

func `==`*(a, b: Listen): bool =
  ## does not include `mirrored` or `preMirror`
  return a.trackName == b.trackName and
    a.artistName == b.artistName and
    a.releaseName == b.releaseName and
    a.artistMbids == b.artistMbids and
    a.trackNumber == b.trackNumber
