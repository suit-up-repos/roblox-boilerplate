local weaponData = {
    [1] = {
        DisplayName = "Kaoru's Bat";
        InternalName = "KaoruBat";
        Kit = "BladeDancer";
        Rarity = 5;
    },
    
    [2] = {
        DisplayName = "Scissor Blade (R)";
        InternalName = "ScissorBladeR";
        Kit = "BladeDancer";
        Rarity = 5;
    },

    [3] = {
        DisplayName = "Death's Embrace";
        InternalName = "DeathsEmbrace";
        Kit = "Reaper";
        Rarity = 5;
    }
}

-- the legendary serializer.
for i, v in ipairs(weaponData) do
    v.ID = i
end

return weaponData