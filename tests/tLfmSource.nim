import std/unittest
include ../src/sources/lfm

suite "Last.FM source":

  suite "Helpers":
    let
      scrobble = newScrobble(
        track = "鳴門海峡",
        artist = "Soichi Terada",
        album = some "Acid Face",
        mbid = some "fabc9908-3a4a-4c79-86bd-1f7e4506b0d8",
        albumArtist = some "Soichi Terada",
        timestamp = some 0,
        trackNumber = some 3,
      )
      track: FMTrack = newFMTrack(
        artist = parseJson """{"mbid": "fabc9908-3a4a-4c79-86bd-1f7e4506b0d8", "#text": "Soichi Terada"}""",
        album = parseJson """{"mbid": "e07d5174-6181-498f-88fb-b92833bb81de", "#text": "Acid Face"}""",
        date = some FMDate(uts: "0", text: ""),
        mbid = scrobble.mbid,
        name = some scrobble.track,
      )
      listen = newListen(
        trackName = cstring get track.name,
        artistName = get getVal(track.artist, "#text"),
        releaseName = getVal(track.album, "#text"),
        recordingMbid = to track.mbid,
        releaseMbid = getVal(track.album, "mbid"),
        artistMbids = parseMbids getStr track.artist{"mbid"},
        trackNumber = scrobble.trackNumber,
        listenedAt = parseDate track.date,
      )

    test "Convert JsonNode to Option[cstring]":
      check getVal(track.artist, "#text") == some(cstring "Soichi Terada")

    test "Convert FMDate to Option[int]":
      check parseDate(track.date) == some(0)

    test "Convert Mbids to Option[seq[cstring]]":
      check parseMbids(get track.mbid) == some(@[cstring "fabc9908-3a4a-4c79-86bd-1f7e4506b0d8"])

    test "Convert FMTrack to Listen":
      var trackListen = listen
      trackListen.trackNumber = none int
      check to(track) == trackListen

    test "Convert seq[FMTrack] to seq[Listen]":
      var trackListen = listen
      trackListen.trackNumber = none int
      check to(@[track, track]) == @[trackListen, trackListen]

    test "Convert Scrobble to Listen":
      var scrobListen = listen
      scrobListen.recordingMbid = none cstring
      scrobListen.releaseMbid = none cstring
      check to(scrobble) == scrobListen
