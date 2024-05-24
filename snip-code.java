    @Value("${push.firebase.configuration.filePath:service-account-file.json}")
    public void setConfigPath(String configPath) {
        this.configPath = configPath;
    }

    public String getDatabaseUrl() {
        return databaseUrl;
    }

    @Value("${push.firebase.configuration.databaseUrl:https://chicpoint-32d7c.firebaseio.com}")
    public void setDatabaseUrl(String databaseUrl) {
        this.databaseUrl = databaseUrl;
    }

    public static final String AndroidClickAction = "chicpoint";

    @PostConstruct
    public void init(){
        //初始化firebase
        initFirebase(configPath, databaseUrl);
    }

    private void initFirebase(String firebaseConfigPath, String fireBaseDatabaseUrl){
        try {
            InputStream refreshToken = new ClassPathResource(firebaseConfigPath).getInputStream();
            FirebaseOptions firebaseOptions = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(refreshToken))
                    .setDatabaseUrl(fireBaseDatabaseUrl)
                    .build();
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(firebaseOptions);
                logger.info("Firebase application has been initialized.");
            }
        }catch (IOException e) {
            logger.error("Firebase application init fail.", e);
        }
    }
