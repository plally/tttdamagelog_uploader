local url = CreateConVar("damagelog_export_url", "http://localhost:8080/intake/damagelog/round", FCVAR_ARCHIVE,
    "URL to export damagelogs to")
local key = CreateConVar("damagelog_export_key", "", FCVAR_ARCHIVE, "Key to use when exporting damagelogs")

local function doRoundUpload(data)
    local body = util.TableToJSON(data)
    HTTP {
        method = "POST",
        url = url:GetString(),
        body = body,
        success = function(code)
            if code == 200 then
                print("Uploaded round")
            else
                print("Failed to upload round with code " .. code)
            end
        end,
        headers = {
            Authorization = key:GetString()
        },
        failed = function(err)
            print("Failed to upload round with error " .. err)
        end
    }
end



local function getData(lastID)
    if type(lastID) ~= "number" then
        error("uhoh")
    end
    return sql.Query(string.format("SELECT * FROM damagelog_oldlogs_v3 WHERE id > %s ORDER BY id ASC LIMIT 100", lastID))
end


local function uploadJob()
    print("Running damagelog export job")
    local lastIDStr = file.Read("last_damagelog_id.txt")
    local lastID = tonumber(lastIDStr)
    if not lastID then
        lastID = 0
    end

    local results = getData(lastID)
    if not results then
        timer.Remove("damagelog_export")
        return
    end
    for _, r in pairs(results) do
        doRoundUpload({
            round = tonumber(r.round),
            map = r.map,
            damagelog = r.damagelog,
            date = tonumber(r.date)
        })
        lastID = tonumber(r.id)
    end

    file.Write("last_damagelog_id.txt", tostring(lastID))
end
print("Starting damagelog export")
timer.Create("damagelog_export", 5, 0, uploadJob)
