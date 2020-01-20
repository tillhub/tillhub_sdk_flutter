const String stagingHost = 'staging-api.tillhub.com';
const String productionHost = 'api.tillhub.com';

const bool isProduction = bool.fromEnvironment('dart.vm.product');

const String allowedHost = isProduction ? productionHost : stagingHost;
