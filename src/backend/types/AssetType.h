// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
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
// update by Sebio 30/08/2024


#pragma once

enum class AssetType : unsigned char {
    UNKNOWN,

    ARCADE_MARQUEE,

    BACKGROUND,

    BOX_FRONT,

    LOGO,

    SCREENSHOT,

    // for tag <bezels></bezels>
    ARCADE_BEZEL,

    // for tag <box2dback></box2dback>
    BOX_BACK,

    // for tag <box2dfront></box2dfront>
    BOX_2DFRONT,

    // for tag <box2dside></box2dside>
    BOX_SPINE,

    // for tag <box3d></box3d>
    BOX_3DFRONT,
    
    // for tag <boxtexture></boxtexture>
    BOX_FULL,
    
    // for tag <extra1></extra1>    
    EXTRA1,  

    // for tag <fanart></fanart>
    FANART,    

    // for tag <images></images>
    IMAGES,

    // for tag <manuals></manuals>
    MANUAL,

    // for tag <map></map>
    MAPS,    

    // for tag <marquee></marquee>
    MARQUEE,

    // for tag <mix></mix>
    MIX,
    
    // for tag <music></music>
    MUSIC,

    // for tag <screenmarquee></screenmarquee>
    SCREEN_MARQUEE,

    // for tag <screenmarqueesmall></screenmarqueesmall>
    SCREEN_MARQUEESMALL,

    // for tag <screenshot></screenshot>
    SCREENSHOT_BIS,

    // for tag <screenshottitle></screenshottitle>
    TITLESCREEN,

    // for tag <steamgrid></steamgrid>
    UI_STEAMGRID, 
    
    // for tag <support></support>
    CARTRIDGE,

    // for tag <supporttexture></supporttexture>
    CARTRIDGETEXTURE,

    // for tag <thumbnail></thumbnail>
    THUMBNAIL,
    
    // for tag <videos></videos>
    VIDEO,

    // for tag <videomix></videomix>
    VIDEOMIX,    

    // for tag <wheel></wheel>
    WHEEL,

    // for tag <wheelcarbon></wheelcarbon>
    WHEEL_CARBON,
    
    // for tag <wheelsteel></wheelsteel>
    WHEEL_STEEL,

    // for asset fullmedia
    FULLMEDIA,

    POSTER,    
    ARCADE_PANEL,
    ARCADE_CABINET_L,
    ARCADE_CABINET_R,
    UI_TILE,
    UI_BANNER,    
};
