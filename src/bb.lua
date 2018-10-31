
function successors(bbs, bb, labels)
    bb.successors = {}
    for _, label in ipairs(labels) do
        local found = false
        for _, block in pairs(bbs) do
            if label == block.label then
                found = true
                table.insert(bb.successors, block)
            end
        end
        assert(found)
    end
end

local bbs = {
    {
        label = "entry"
    }, {
        label = "l1"
    }, {
        label = "l2"
    }, {
        label = "l3"
    }
}

successors(bbs, bbs[1], {"l1", "l2"})

for i, v in ipairs(bbs[1].successors) do
    print(i, v.label)
end
