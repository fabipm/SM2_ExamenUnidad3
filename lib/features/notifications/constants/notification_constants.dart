/// Constantes para el sistema de notificaciones
class NotificationConstants {
  static const String collection = 'notifications';
  
  // Umbrales de notificación
  static const double warningThreshold = 80.0; // 80%
  static const double exceededThreshold = 100.0; // 100%
  
  // Mensajes de notificación
  static const String warning80Title = '⚠️ Presupuesto al 80%';
  static const String exceeded100Title = '🚨 Presupuesto alcanzado';
  static const String overspentTitle = '❌ Presupuesto excedido';
  
  // Plantillas de mensajes
  static String getWarning80Message(String categoryName, double currentAmount, double budgetAmount) {
    return 'Has gastado S/ ${currentAmount.toStringAsFixed(2)} de S/ ${budgetAmount.toStringAsFixed(2)} en "$categoryName". ¡Cuidado con los próximos gastos!';
  }
  
  static String getExceeded100Message(String categoryName, double budgetAmount) {
    return 'Has alcanzado el límite de S/ ${budgetAmount.toStringAsFixed(2)} en "$categoryName". Considera revisar tus gastos.';
  }
  
  static String getOverspentMessage(String categoryName, double currentAmount, double budgetAmount) {
    final overspent = currentAmount - budgetAmount;
    return 'Has excedido el presupuesto de "$categoryName" por S/ ${overspent.toStringAsFixed(2)}. Total gastado: S/ ${currentAmount.toStringAsFixed(2)}.';
  }
  
  // Canales de notificación local
  static const String channelId = 'budget_notifications';
  static const String channelName = 'Notificaciones de Presupuesto';
  static const String channelDescription = 'Alertas cuando los gastos se acercan o exceden el presupuesto establecido';
  
  // IDs únicos para notificaciones locales
  static int getNotificationId(String planId, String categoryId, String type) {
    return '$planId$categoryId$type'.hashCode.abs();
  }
}