config = {}

config.blacklist = 3 -- dias que irá ficar de blacklist

config.adminperm = "admin.permissao"

config.prices = {
    kgprice = 10000,
}

config.organizations = {
    ['ELEMENTS'] = {
        ownerGroup = 'ELEMENTS1',
        groups = {
            [1] = {onService = 'ELEMENTS1', offService = 'ELEMENTSOFF', discordid = '' },
            [2] = {onService = 'ELEMENTS2', offService = 'ELEMENTSOFF', discordid = '' },
            [3] = {onService = 'ELEMENTS3', offService = 'ELEMENTSOFF', discordid = '' },
            [4] = {onService = 'ELEMENTS4', offService = 'ELEMENTSOFF', discordid = '' },
            [5] = {onService = 'ELEMENTS5', offService = 'ELEMENTSOFF', discordid = '1053090349486190603' },
        },
        modGroups = {
            'ELEMENTS1', 'ELEMENTS2'
        },
        -- mapImprovements = {
        --     [1] = { id = 1, ipl = 'barragem_ipl_01', price = 1, name = 'Favela Nível 1', img1 = 'https://cdn.discordapp.com/attachments/954936708569378876/1052417014188216320/istockphoto-1020868854-612x612.jpg', img2 = 'house', description = 'Uma oportunidade de conseguir ampliar sua favela, tendo mais spots para invasões, troca de tiros e casas para futuros moradores!' },
        --     [2] = { id = 2, ipl = 'favela_barbe_barragem', price = 1, name = 'Favela Nível 2', img1 = 'https://cdn.discordapp.com/attachments/954936708569378876/1052417014188216320/istockphoto-1020868854-612x612.jpg', img2 = 'house', description = 'Uma oportunidade de conseguir ampliar sua favela, tendo mais spots para invasões, troca de tiros e casas para futuros moradores!' },
        --     [3] = { id = 3, ipl = 'favela_roupas_barragem', price = 2, name = 'Favela Nível 3', img1 = 'https://cdn.discordapp.com/attachments/954936708569378876/1052417014188216320/istockphoto-1020868854-612x612.jpg', img2 = 'house', description = 'Uma oportunidade de conseguir ampliar sua favela, tendo mais spots para invasões, troca de tiros e casas para futuros moradores!' },
        --     [4] = { id = 4, ipl = 'barragem_ipl_02', price = 3, name = 'Favela Nível 4', img1 = 'https://cdn.discordapp.com/attachments/954936708569378876/1052417014188216320/istockphoto-1020868854-612x612.jpg', img2 = 'house', description = 'Uma oportunidade de conseguir ampliar sua favela, tendo mais spots para invasões, troca de tiros e casas para futuros moradores!' },
        -- },
        center = vec3(145.74,-1952.58,23.32),
        maxdistance = {
            chest = 100,
        },
        maxMembers = 30,
        maxChest = 5000,
    },
}


