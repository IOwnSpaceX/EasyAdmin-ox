-- ==================== EASYADMIN STAFF RANK CONFIG ====================
                        -- By: Liam (IOwnSpaceX) --

Config = {}

Config.StaffRanks = {
    ["easyadmin.stafftag.owner"] = "Owner",
    ["easyadmin.stafftag.admin"] = "Admin",
    ["easyadmin.stafftag.mod"] = "Moderator",
    ["easyadmin.stafftag.senior"] = "Senior Admin",
    ["easyadmin.stafftag.dev"] = "Developer",
    
    -- Fallback
    ["easyadmin"] = "Staff",
}

-- Order matters! Higher ranks should be checked first
Config.RankOrder = {
    "easyadmin.stafftag.owner",
    "easyadmin.stafftag.admin",
    "easyadmin.stafftag.senior",
    "easyadmin.stafftag.mod",
    "easyadmin.stafftag.dev"
}