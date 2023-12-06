local neorg = require('neorg.core')

local module = neorg.modules.create('external.custom-links')

module.load = function ()
    -- If I ever needed the load function
end

module.config.public = {
    handlers = {}
}

module.private = {

    is_link = function (node)
        if node:type() == 'anchor_definition' then
            return true
        end

        if node:type() == 'link' then
            return true
        end

        return false
    end,

    get_link_root = function (node)
        while module.private.is_link(node) == false do
            if node:parent() == nil then
                node = nil
                break
            end
            node = node:parent()
        end

        return node
    end,

    get_link_details = function (node)
        local node_label = ""
        local node_link = ""
        local node_attrs = {}

        for child in node:iter_children() do
            local type = child:type()
            if type == "link_description" then
                node_label = vim.treesitter.get_node_text(child, 0):sub(2,-2)
            elseif type == "link_location" then
                node_link = vim.treesitter.get_node_text(child, 0):sub(2,-2)
            elseif type == "attribute" then
                table.insert(node_attrs, vim.treesitter.get_node_text(child, 0):sub(2,-2))
            end
        end

        return {
            label = node_label,
            link  = node_link,
            attrs = node_attrs,
        }
    end,

    link_clicked = function ()
        local node = vim.treesitter.get_node()
        local link = module.private.get_link_root(node)
        local details = module.private.get_link_details(link)

        for _, attr in ipairs(details.attrs) do
            if module.config.public.handlers[attr] ~= nil then
                module.config.public.handlers[attr](details)
            end
        end
    end,
}

module.on_event = function (event)
    if event.split_type[2] == "core.esupports.hop.hop-link" then
        module.private.link_clicked()
    end
end

module.events.subscribed = {
    ["core.keybinds"] = {
        ["core.esupports.hop.hop-link"] = true,
    },
}

return module
