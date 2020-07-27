module Pages.Music exposing (Params, Model, Msg, page)

import Shared exposing (sendAction, sendActions)
import Element exposing (..)
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Element.Background as Background
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Html exposing (..)
import Html.Attributes exposing (..)
import Svg.Attributes
import FeatherIcons
import Request
import WSDecoder exposing (SongObj, ItemDetails)
--import Components exposing ()


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    { currentlyPlaying : ItemDetails
    , song_list : List SongObj
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( {currentlyPlaying = shared.currentlyPlaying, song_list = shared.song_list}
    , sendAction """{"jsonrpc": "2.0", "method": "AudioLibrary.GetSongs", "params": { "limits": { "start" : 0, "end": 25 }, "properties": [ "artist", "duration", "album", "track" ], "sort": { "order": "ascending", "method": "track", "ignorearticle": true } }, "id": "libSongs"}"""
    )



-- UPDATE


type Msg
    = SetCurrentlyPlaying SongObj


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCurrentlyPlaying song ->
            ( model
            , sendActions 
                [ {-clear the queue-} """{"jsonrpc": "2.0", "id": 0, "method": "Playlist.Clear", "params": {"playlistid": 0}}"""
                , {-add the next song-}("""{"jsonrpc": "2.0", "id": 1, "method": "Playlist.Add", "params": {"playlistid": 0, "item": {"songid": """ ++ String.fromInt(song.songid) ++ """}}}""")
                , {-play-} """{"jsonrpc": "2.0", "id": 0, "method": "Player.Open", "params": {"item": {"playlistid": 0}}}"""
            ])


save : Model -> Shared.Model -> Shared.Model
save model shared =
    { shared | currentlyPlaying = model.currentlyPlaying, song_list = model.song_list }


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( {model | song_list = shared.song_list} , Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


featherButton : ( FeatherIcons.Icon, msg ) -> Element msg
featherButton ( icon, action ) =
    Input.button [paddingXY 5 3]
        { onPress = Just action
        , label = Element.html (icon |> FeatherIcons.withSize 24 |> FeatherIcons.toHtml [ Svg.Attributes.color "lightgrey" ])
        }

-- VIEW

view : Model -> Document Msg
view model =
    { title = "Music"
    , body = 
        [ Element.text "Songs:"
        , column [Element.height fill, Element.width fill, scrollbars, clipY, spacingXY 5 7]
            (List.map 
                (\song -> 
                    row [Element.width fill, paddingXY 5 5, Background.color (rgb 0.2 0.2 0.2), mouseOver [ Background.color (rgb 0.4 0.4 0.4) ], Element.Events.onDoubleClick (SetCurrentlyPlaying song)] 
                        [ featherButton (FeatherIcons.play, (SetCurrentlyPlaying song))
                        , featherButton (FeatherIcons.thumbsUp, (SetCurrentlyPlaying song))
                        , el [Font.color (Element.rgb 0.8 0.8 0.8)] (Element.text song.label)
                        , row [alignRight]
                            (List.map
                                (\artist -> 
                                    el [Font.color (Element.rgb 0.8 0.8 0.8), paddingXY 5 0] (Element.text artist)
                                ) 
                                song.artist
                            )
                        , el [alignRight, Font.color (Element.rgb 0.8 0.8 0.8)] (Element.text (String.fromInt(song.duration)))
                        , featherButton (FeatherIcons.moreHorizontal, (SetCurrentlyPlaying song))
                        ]
                ) 
            model.song_list)
        ]
    }