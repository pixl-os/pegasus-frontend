// Pegasus Frontend
// Copyright (C) 2017-2019  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// Update by Sebio 30/08/2024

#pragma once

#include "types/AssetType.h"
#include "utils/HashMap.h"
#include "utils/MoveOnly.h"

#include <QStringList>
#include <QObject>

#include <array>

#ifdef Q_CC_MSVC
// MSVC has troubles with forward declared QML model types
#include "model/gaming/Game.h"
#endif

namespace model { class Game; }

namespace model {
class Assets : public QObject {
    Q_OBJECT

public:
    const std::array<QString, 1> MEDIA_DIRS {
        QStringLiteral("/media/"),
    };

    // NOTE: The entries are ordered by priority
    const HashMap<AssetType, QStringList, EnumHash> ASSET_DIRS {
        // multi posibility
        { AssetType::ARCADE_MARQUEE, {
            QStringLiteral("marquee"),
            QStringLiteral("screenmarquee"),
            QStringLiteral("screenmarqueesmall"),
            QStringLiteral("steamgrid"),
        }},
        { AssetType::BACKGROUND, {
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        { AssetType::BOX_FRONT, {
            QStringLiteral("box3d"),
            QStringLiteral("support"),
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
            QStringLiteral("supporttexture"),
            QStringLiteral("thumbnail"),
        }},
        { AssetType::LOGO, {
            QStringLiteral("wheel"),
            QStringLiteral("wheelcarbon"),
            QStringLiteral("wheelsteel"),
        }},
        { AssetType::SCREENSHOT, {
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        { AssetType::FULLMEDIA, {         
            QStringLiteral("mix"),
            QStringLiteral("fanart"),
            QStringLiteral("screenshot"),
            QStringLiteral("screenshottitle"),
            QStringLiteral("image"),
            QStringLiteral("images"),
            QStringLiteral("thumbnail"),
            QStringLiteral("extra1"),
            QStringLiteral("box3d"),
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
            QStringLiteral("support"),
            QStringLiteral("supporttexture"),
            QStringLiteral("boxback"),
            QStringLiteral("boxBack"),
            QStringLiteral("box2dback"),
            QStringLiteral("boxfull"),
            QStringLiteral("boxFull"),
            QStringLiteral("boxtexture"),
        }},

        // solo posibility
        // for tag <bezels></bezels>
        { AssetType::ARCADE_BEZEL, {
            QStringLiteral("bezel"), // specific with arrm
            QStringLiteral("bezels"), // specific with arrm
        }},
        // for tag <box2dback></box2dback>
        { AssetType::BOX_BACK, {
            QStringLiteral("boxback"),
            QStringLiteral("boxBack"),
            QStringLiteral("box2dback"),
        }},
        // for tag <box2dfront></box2dfront>
        { AssetType::BOX_2DFRONT, {    
            QStringLiteral("boxfront"),
            QStringLiteral("boxFront"),
            QStringLiteral("box2dfront"),
        }},
        // for tag <box2dside></box2dside>
        { AssetType::BOX_SPINE, {
            QStringLiteral("boxside"),
            QStringLiteral("boxSide"),
            QStringLiteral("box2dside"),
        }},
        // for tag <box3d></box3d>
        { AssetType::BOX_3DFRONT, {
            QStringLiteral("box3d"),
        }},
        // for tag <boxtexture></boxtexture>
        { AssetType::BOX_FULL, {
            QStringLiteral("boxfull"),
            QStringLiteral("boxFull"),
            QStringLiteral("boxtexture"),
        }},
        // for tag <extra1></extra1>
        { AssetType::EXTRA1, {
            QStringLiteral("extra1"), // flyer specific with arrm
        }},
        // for tag <fanart></fanart>
        { AssetType::FANART, {
            QStringLiteral("fanart"),
        }},
        // for tag <images></images>
        { AssetType::IMAGES, {
            QStringLiteral("image"),
            QStringLiteral("images"),
        }},
        // for tag <manuals></manuals>
        { AssetType::MANUAL, {
            QStringLiteral("manual"),
            QStringLiteral("manuals"),
        }},
        // for tag <map></map>
        { AssetType::MAPS, {
            QStringLiteral("map"),
            QStringLiteral("maps"),            
        }},
        // for tag <marquee></marquee>
        { AssetType::MARQUEE, {
            QStringLiteral("marquee"),
        }},
        // for tag <mix></mix>
        { AssetType::MIX, {
            QStringLiteral("mix"), // specific with arrm
        }},
        // for tag <music></music>
        { AssetType::MUSIC, {
            QStringLiteral("music"), // specific with arrm
        }},
        // for tag <screenmarquee></screenmarquee>
        { AssetType::SCREEN_MARQUEE, {  
            QStringLiteral("screenmarquee"),
        }},
        // for tag <screenmarqueesmall></screenmarqueesmall>
        { AssetType::SCREEN_MARQUEESMALL, {      
            QStringLiteral("screenmarqueesmall"),
        }},
        // for tag <screenshot></screenshot>
        { AssetType::SCREENSHOT_BIS, {
            QStringLiteral("screenshot"),
        }},
        // for tag <screenshottitle></screenshottitle>
        { AssetType::TITLESCREEN, {
            QStringLiteral("screenshottitle"),
        }},
        // for tag <steamgrid></steamgrid>
        { AssetType::UI_STEAMGRID, {
            QStringLiteral("steamgrid"),
        }},
        // for tag <support></support>
        { AssetType::CARTRIDGE, {
            QStringLiteral("support"),
        }},
        // for tag <supporttexture></supporttexture>
        { AssetType::CARTRIDGETEXTURE, {
            QStringLiteral("supporttexture"),
        }},
        // for tag <thumbnail></thumbnail>
        { AssetType::THUMBNAIL, {
            QStringLiteral("thumbnail"),
        }},
        // for tag <videos></videos>
        { AssetType::VIDEO, {
            QStringLiteral("video"),
            QStringLiteral("videos"),
        }},
        // for tag <videomix></videomix>
        { AssetType::VIDEOMIX, {
            QStringLiteral("videomix"), // specific with arrm
        }},
        // for tag <wheel></wheel>
        { AssetType::WHEEL, {
            QStringLiteral("wheel"),
        }},
        // for tag <wheelcarbon></wheelcarbon>
        { AssetType::WHEEL_CARBON, {
            QStringLiteral("wheelcarbon"),
        }},
        // for tag <wheelsteel></wheelsteel>
        { AssetType::WHEEL_STEEL, {         
            QStringLiteral("wheelsteel"),
        }},
    };

    // NOTE: by manually listing the properties (instead of eg. a Map),
    //       it is also possible to refer the same data by a different name
    // TODO: these could be optimized, see
    //       https://doc.qt.io/qt-5/qtqml-cppintegration-data.html (Sequence Type to JavaScript Array)
#define GEN(qmlname, enumname) \
    const QString& qmlname() { return getFirst(AssetType::enumname); } \
    const QStringList& qmlname##List() { return get(AssetType::enumname); } \
    Q_PROPERTY(QString qmlname READ qmlname CONSTANT) \
    Q_PROPERTY(QStringList qmlname##List READ qmlname##List CONSTANT) \

    GEN(box2d, BOX_2DFRONT)
    GEN(box3d, BOX_3DFRONT)
    GEN(boxFront, BOX_FRONT)
    GEN(boxBack, BOX_BACK)
    GEN(boxSpine, BOX_SPINE)
    GEN(boxFull, BOX_FULL)
    GEN(cartridge, CARTRIDGE)
    GEN(cartridgetexture, CARTRIDGETEXTURE)
    GEN(logo, LOGO)
    GEN(wheel, WHEEL)
    GEN(wheelcarbon, WHEEL_CARBON)
    GEN(wheelsteel, WHEEL_STEEL)

    GEN(poster, POSTER)
    GEN(fanart, FANART)

    GEN(marquee, ARCADE_MARQUEE)
    GEN(bezel, ARCADE_BEZEL)
    GEN(panel, ARCADE_PANEL)
    GEN(cabinetLeft, ARCADE_CABINET_L)
    GEN(cabinetRight, ARCADE_CABINET_R)

    GEN(screenmarquee, SCREEN_MARQUEE)
    GEN(screenmarqueesmall, SCREEN_MARQUEESMALL)

    GEN(tile, UI_TILE)
    GEN(banner, UI_BANNER)
    GEN(steam, UI_STEAMGRID)
    GEN(background, BACKGROUND)
    GEN(music, MUSIC)

    GEN(image, IMAGES)
    GEN(screenshot, SCREENSHOT)
    GEN(screenshot_bis, SCREENSHOT_BIS)
    GEN(thumbnail, THUMBNAIL)
    GEN(titlescreen, TITLESCREEN)

    GEN(video, VIDEO)
    GEN(videomix, VIDEOMIX)

    GEN(manual,MANUAL)

    GEN(maps,MAPS)

    GEN(extra1, EXTRA1)

    GEN(mix, MIX)

    GEN(fullmedia, FULLMEDIA)

#undef GEN

    // deprecated fallacks
    // TODO: remove
    Q_PROPERTY(QStringList screenshots READ screenshotList CONSTANT)
    Q_PROPERTY(QStringList videos READ videoList CONSTANT)

public:
    explicit Assets(QObject* parent);

    Assets& add_file(AssetType, QString);
    Assets& add_uri(AssetType, QString);
    //new fonction to add link between assets and game
    Assets& setGame(model::Game*);

private:
    const QStringList& get(AssetType, bool searchFirstOnly = false);
    const QString& getFirst(AssetType);
    const QString m_log_tag = "Assets";
    HashMap<AssetType, QStringList, EnumHash> m_asset_lists;

    const Game& game() const { return *m_game; }
    Game* gameMut() const { return m_game; }
    Game* m_game;
    size_t find_asset_for_game(AssetType key, bool searchFirstOnly = false);
};

} // namespace model
