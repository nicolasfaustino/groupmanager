Vue.createApp({
    data(){
        return {
            visible: false,
            visiblehome: false,
            visiblechest: false,
            visiblebank: false,
            visiblemap: false,
            page: 'home',
            data: {},
            findUser: "",
            _playerList: [],
            playerList: [],
            chestLogs: [],
            banklogs: [],
            mapupgrades: [],

            selectedPlayer: '',
            selectedProduct: {},

            playerPassport: '',
            donationValue: ''
        }
    },

    methods: {
        openUI(args) {
            this.visible = true;
            this.visiblehome = true;
            this.data = args[0];
            this._playerList = this.data.organization_members;
            this.playerList = this.data.organization_members;
            this.playerList = this.data.organization_members;
            this.chestLogs = this.data.logs;
            this.banklogs = this.data.logsmoney;
            this.mapupgrades = this.data.mapinfos;
            console.log(JSON.stringify(this.data.logs))
        },

        closeUI(){
            this.visible = false;
        },

        redirect(route){
            this.page = route;
        },

        findUserByName(){   
            if(this.findUser.length > 0){
                this.playerList = this._playerList.filter(el => (el.name.toLowerCase()).startsWith(this.findUser.toLowerCase()));
                return;
            }

            this.playerList = this._playerList;
        },

        async addPlayer(){
            const group = this.$refs.groupSelector.value;
            const res = await this.post("invite-member", {user_id: parseInt(this.playerPassport), group});
            if(res.success){
                this.playerPassport = '';
            }
        },

        async donateMoney(){
           const res = await this.post('donate-money', {value: parseInt(this.donationValue)});
           if(res){
                this.donationValue = '';
           }
        },

        async retrieveMoney(){
            const res = await this.post('retrieve-money', {value: parseInt(this.retrieveValue)});
            if(res){
                 this.retrieveValue = '';
            }
         },

        async upgradeChest(){
            const res = await this.post('chest-upgrade', {value: parseInt(this.chestValue)});
            if(res){
                 this.chestValue = '';
            }
         },

        selectPlayer(user_id){
            if(this.selectedPlayer === user_id) return this.selectedPlayer = '';
            this.selectedPlayer = user_id;
        },

        selectProduct(product,id){
            this.selectedProduct = {...product,id: id + 1};
        },

        async buyProduct(){
            const res = await this.post('buy-map',{id: this.selectedProduct.id});
            if(res){
                this.selectedProduct = {};
            }
        },

        async update(){
            const res = await this.post("updateUI");
        },

        changeFilter(filter){
            switch (filter) {
                case 'donations':
                    this.playerList = this._playerList;
                    this.playerList = this.playerList.sort((p1,p2) => p1.donated_money - p2.donated_money).reverse();
                    break;
                
                case 'online':
                    this.playerList = this._playerList;
                    this.playerList = this.playerList.filter(plr => parseInt(plr.status) === 0);
                    break;

                default:
                    break;
            }
        },

        async makeAction(action){
            const res = await this.post(action,{user_id: this.selectedPlayer});
        },

        async chestLocal(action){
            const res = await this.post(action, {orgname: this.data.org_name});
        },

        async mapupgrade(action, id){
            console.log(action, id)
            const res = await this.post(action, {id});
        },

        async makeAction2(action){
            if (action == "home") {
                this.visiblehome = true;
                this.visiblechest = false;
                this.visiblebank = false;
                this.visiblemap = false;
                $("#map").removeClass('active');
                $("#chest").removeClass('active');
                $("#bank").removeClass('active');
                $("#home").addClass('active');
            } else if (action == "chest") {
                this.visiblehome = false;
                this.visiblechest = true;
                this.visiblebank = false;
                this.visiblemap = false;
                $("#map").removeClass('active');
                $("#home").removeClass('active');
                $("#bank").removeClass('active');
                $("#chest").addClass('active');
            } else if (action == "map") {
                this.visiblehome = false;
                this.visiblechest = false;
                this.visiblebank = false;
                this.visiblemap = true;
                $("#home").removeClass('active');
                $("#chest").removeClass('active');
                $("#bank").removeClass('active');
                $("#map").addClass('active');
            } else if (action == "bank") {
                this.visiblehome = false;
                this.visiblechest = false;
                this.visiblemap = false;
                this.visiblebank = true;
                $("#home").removeClass('active');
                $("#chest").removeClass('active');
                $("#map").removeClass('active');
                $("#bank").addClass('active');
            }
        },

        post(endpoint, data){
            return fetch(`http://dev-gm/${endpoint}`,{
                method: "POST",
                body: JSON.stringify(data || {}),
            }).then(( res ) => res.json());
        }
    },

    mounted(){
        window.addEventListener('message', ({data}) => {
            const [action,...args] = data;
            this[action]([...args]);
        })

        window.addEventListener('keydown', async (event) =>{
            if( event.keyCode === 27 ) {
                const res = await this.post("close",{closeServer: true});
                if(res){
                    this.visible = false;
                    this.visiblehome = false;
                    this.visiblechest = false;
                    this.visiblebank = false;
                    this.visiblemap = false;
                }
            }
        });
    }
}).mount("#app");


