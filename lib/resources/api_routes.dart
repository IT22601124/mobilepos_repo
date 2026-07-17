class ApiRoutes {
  // static const String serverUrl = 'http://10.0.2.2:5000';
  static const String serverUrl = 'https://mpos.studiorespectweddings.com';
  static const bool allowBadCertificates = true;
  static const String baseUrl = '$serverUrl/api/';

  static const String checkConnection = 'health';
  static const String register = 'auth';
  static const String login = 'auth/login';
  static const String authUsers = 'auth/users';
  static const String verifyToken = 'auth/verify-token';

  static const String categories = 'categories';
  static const String brands = 'brands';
  static const String units = 'units';
  static const String suppliers = 'suppliers';
  static const String products = 'products';
  static const String productSuppliers = 'product-suppliers';
  static const String stockMovements = 'stock-movements';
  static const String productBatches = 'product-batches';
  static const String productImages = 'product-images';
  static const String productVariants = 'product-variants';
  static const String taxes = 'taxes';
  static const String discounts = 'discounts';
  static const String customers = 'customers';
  static const String customerCreditTransactions =
      'customer-credit-transactions';
  static const String branches = 'branches';
  static const String roles = 'roles';
  static const String posSales = 'pos-sales';
  static const String dashboard = 'dashboard';

  static const String reportSummary = 'pos-sales/reports/summary';
  static const String reportSales = 'pos-sales/reports/sales';
  static const String reportCashiers = 'pos-sales/reports/cashiers';
  static const String reportProducts = 'pos-sales/reports/products';
  static const String reportItems = 'pos-sales/reports/items';
  static const String reportInventory = 'pos-sales/reports/inventory';
  static const String reportPayments = 'pos-sales/reports/payments';
  static const String reportTaxDiscounts = 'pos-sales/reports/tax-discounts';
  static const String reportCredit = 'pos-sales/reports/credit';

  static const String posSettings = 'pos-settings';
  static const String posSettingsPaymentMethods =
      'pos-settings/payment-methods';
  static const String posSettingsReceipt = 'pos-settings/receipt';
  static const String posSettingsDiscountRules = 'pos-settings/discount-rules';

  static const String storeProfile = 'store-profile';
  static const String storeProfileLogo = 'store-profile/logo';
  static const String settingsStoreProfile = 'settings/store-profile';
  static const String settingsStoreProfileLogo = 'settings/store-profile/logo';
}
