export type WeaponInfo = {
    DisplayName: string;
    InternalName: string;
    Kit: string;
    Rarity: number;
}

-- see PlayerContainer.lua
export type tempdata = {
    lastAspectChange: number
}

-- see PlayerContainer.lua
export type InventoryAspect = {
    ID: number;
    Level: number;
    Experience: number;
    LimitBreak: number;

    Artifacts: {number: number}; -- value -> position in userdata.Artifacts
    Weapon: number; -- position in userdata.Weapons
}

export type InvArtifact = {
    Name: string;
    Class: string;
    Stats: {string: number};
}

export type InvWeapon = {
    ID: number;
    Stats: {string: number};
    Effects: {string: number} | nil;
    UID: string;
}

-- see PlayerContainer.lua
export type playerdata = {}



return {}