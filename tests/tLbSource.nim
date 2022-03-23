import std/[unittest, os, asyncdispatch]
include ../src/sources/lb

suite "ListenBrainz source":

  suite "to Helpers":
    test "Convert some `Option[seq[cstring]]` to `Option[seq[string]]`":
      let
        cstringSeq: Option[seq[cstring]] = some @[cstring "test!", cstring "test?"]
        stringSeq: Option[seq[string]] = some @["test!", "test?"]
      check to(cstringSeq) == stringSeq

    test "Convert none `Option[seq[cstring]]` to `Option[seq[string]]`":
      let
        cstringSeq: Option[seq[cstring]] = none seq[cstring]
        stringSeq: Option[seq[string]] = none seq[string]
      check to(cstringSeq) == stringSeq

    test "Convert some `Option[seq[string]]` to `Option[seq[cstring]]`":
      let
        stringSeq: Option[seq[string]] = some @["test!", "test?"]
        cstringSeq: Option[seq[cstring]] = some @[cstring "test!", cstring "test?"]
      check to(stringSeq) == cstringSeq

    test "Convert none `Option[seq[string]]` to `Option[seq[cstring]]`":
      let
        stringSeq: Option[seq[string]] = none seq[string]
        cstringSeq: Option[seq[cstring]] = none seq[cstring]
      check to(stringSeq) == cstringSeq

    test "Convert some `Option[string]` to `Option[cstring]`":
      let
        str: Option[string] = some "test!"
        cstr: Option[cstring] = some cstring "test!"
      check to(str) == cstr

    test "Convert none `Option[string]` to `Option[cstring]`":
      let
        str: Option[string] = none string
        cstr: Option[cstring] = none cstring
      check to(str) == cstr

    test "Convert some `Option[cstring]` to `Option[string]`":
      let
        cstr: Option[cstring] = some cstring "test!"
        str: Option[string] = some "test!"
      check to(cstr) == str

    test "Convert none `Option[cstring]` to `Option[string]`":
      let
        cstr: Option[cstring] = none cstring
        str: Option[string] = none string
      check to(cstr) == str

    test "Convert `Track` to `APIListen` (Simple)":
      let
        trackName = "track"
        artistName = "artist"
        listenedAt = some 1
        track = newTrack(cstring trackName, cstring artistName, listenedAt = listenedAt)
        apiListen = newAPIListen(listenedAt = listenedAt, trackMetadata = newTrackMetadata(trackName, artistName))
        newAPIListen = to track
      check newAPIListen.listenedAt == apiListen.listenedAt
      check newAPIListen.trackMetadata.trackName == apiListen.trackMetadata.trackName
      check newAPIListen.trackMetadata.artistName == apiListen.trackMetadata.artistName

    test "Convert `seq[Track]` to `seq[APIListen]` (Simple)":
      let
        trackName = "track"
        artistName = "artist"
        listenedAt = some 1
        tracks = @[newTrack(cstring trackName, cstring artistName, listenedAt = listenedAt)]
        apiListens = @[newAPIListen(listenedAt = listenedAt, trackMetadata = newTrackMetadata(trackName, artistName))]
        newAPIListens = to tracks
      check newAPIListens[0].listenedAt == apiListens[0].listenedAt
      check newAPIListens[0].trackMetadata.trackName == apiListens[0].trackMetadata.trackName
      check newAPIListens[0].trackMetadata.artistName == apiListens[0].trackMetadata.artistName

    test "Convert `Track` to `APIListen` to `Track`":
      let
        trackName = "track"
        artistName = "artist"
        listenedAt = some 1
        track = newTrack(cstring trackName, cstring artistName, listenedAt = listenedAt)
        apiListen = to track
        newTrack = to apiListen
      check newTrack.trackName == track.trackName
      check newTrack.artistName == track.artistName
      check newTrack.releaseName == track.releaseName
      check newTrack.recordingMbid == track.recordingMbid
      check newTrack.releaseMbid == track.releaseMbid
      check newTrack.artistMbids == track.artistMbids
      check newTrack.trackNumber == track.trackNumber
      check newTrack.listenedAt == track.listenedAt
      check newTrack.mirrored == track.mirrored
      check newTrack.preMirror == track.preMirror

    test "Convert `APIListen` to `Track` (Simple)":
      let
        trackName = "track"
        artistName = "artist"
        apiListen = newAPIListen(trackMetadata = newTrackMetadata(trackName, artistName))
        preMirror = some true
        track = newTrack(cstring trackName, cstring artistName, preMirror = preMirror)
        newTrack = to(apiListen, preMirror)
      check newTrack.trackName == track.trackName
      check newTrack.artistName == track.artistName
      check newTrack.preMirror == track.preMirror

    test "Convert `seq[APIListen]` to `seq[Track]` (Simple)":
      let
        apiListens = @[newAPIListen(trackMetadata = newTrackMetadata("track", "artist")), newAPIListen(trackMetadata = newTrackMetadata("track1", "artist1"))]
        tracks = @[newTrack(cstring "track", cstring "artist"), newTrack(cstring "track1", cstring "artist1")]
        newTracks = to(apiListens)
      check newTracks == tracks

    test "Convert `APIListen` to `Track` to `APIListen`":
      let
        trackName = "track"
        artistName = "artist"
        apiListen = newAPIListen(trackMetadata = newTrackMetadata(trackName, artistName))
        preMirror = some true
        track = to(apiListen, preMirror)
        newAPIListen = to track
      check newAPIListen.listenedAt == apiListen.listenedAt
      check  newAPIListen.insertedAt == apiListen.insertedAt
      check newAPIListen.userName == apiListen.userName
      check newAPIListen.listenedAtIso == apiListen.listenedAtIso
      check newAPIListen.recordingMsid == apiListen.recordingMsid
      check newAPIListen.playingNow == apiListen.playingNow
      check newAPIListen.trackMetadata.trackName == apiListen.trackMetadata.trackName
      check newAPIListen.trackMetadata.artistName == apiListen.trackMetadata.artistName
      check newAPIListen.trackMetadata.releaseName == apiListen.trackMetadata.releaseName
      check get(newAPIListen.trackMetadata.additionalInfo, AdditionalInfo()).recordingMbid == get(apiListen.trackMetadata.additionalInfo, AdditionalInfo()).recordingMbid
      check get(newAPIListen.trackMetadata.additionalInfo, AdditionalInfo()).releaseMbid == get(apiListen.trackMetadata.additionalInfo, AdditionalInfo()).releaseMbid
      check get(newAPIListen.trackMetadata.additionalInfo, AdditionalInfo()).artistMbids == get(apiListen.trackMetadata.additionalInfo, AdditionalInfo()).artistMbids
      check get(newAPIListen.trackMetadata.additionalInfo, AdditionalInfo()).tracknumber == get(apiListen.trackMetadata.additionalInfo, AdditionalInfo()).tracknumber

  suite "API tools":
    setup:
      let
        lb = newAsyncListenBrainz()
        username = cstring os.getEnv("LISTENBRAINZ_USER")

    test "Get now playing":
      let nowPlaying = waitFor lb.getNowPlaying(username)

    test "Get recent tracks":
      let recentTracks = waitFor lb.getRecentTracks(username, preMirror = false)
      check recentTracks.len == 100

    test "Initialise user":
      let newUser = waitFor lb.initUser(username)

    test "Update user":
      var user = newUser(userId = username, services = [Service.listenBrainzService: newServiceUser(Service.listenBrainzService, username), Service.lastFmService: newServiceUser(Service.lastFmService)])
      let updatedUser = waitFor lb.updateUser(user)

    ## Cannot be tested outside JS backend
    # test "Page user":
    #   let inc = 10
    #   var endInt = 10
    #   discard lb.pageUser(user, endInt, inc)
    #   check endInt == 20

    # test "Submit mirror queue":
    #   var user = newUser(userId = username, services = [Service.listenBrainzService: newServiceUser(Service.listenBrainzService, username), Service.lastFmService: newServiceUser(Service.lastFmService)])
    #   user.listenHistory = @[newTrack("track 1", "artist", preMirror = some false, mirrored = some false)]
    #   discard lb.submitMirrorQueue(user)