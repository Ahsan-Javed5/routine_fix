import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/occasional_model.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class ReminderController extends GetxController {
  final RxList<OccasionalModel> occasionalList = <OccasionalModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    occasionalList.value = await DbService.instance.loadOccasional();
  }

  Future<void> updateReminder(
    OccasionalModel item, {
    required String title,
    required String description,
    required DateTime date,
    String? time,
  }) async {
    item.title = title;
    item.description = description;
    item.date = date;
    item.time = time;
    await DbService.instance.saveOccasional(occasionalList);
    occasionalList.refresh();
    await NotificationService.instance
        .scheduleOccasionalReminder(item.id, item.title, item.date, item.time);
  }

  Future<void> addReminder(OccasionalModel item) async {
    occasionalList.add(item);
    await DbService.instance.saveOccasional(occasionalList);
    await NotificationService.instance
        .scheduleOccasionalReminder(item.id, item.title, item.date, item.time);
  }

  Future<void> restoreItems(List<OccasionalModel> items) async {
    occasionalList.value = items;
    await DbService.instance.saveOccasional(occasionalList);
  }

  Future<void> confirmDone(OccasionalModel item, bool done) async {
    item.isConfirmed = done;
    item.confirmedAt = DateTime.now();
    await DbService.instance.saveOccasional(occasionalList);
    occasionalList.refresh();
  }

  Future<void> deleteReminder(String id) async {
    occasionalList.removeWhere((e) => e.id == id);
    await DbService.instance.saveOccasional(occasionalList);
  }

  String newId() => const Uuid().v4();

  /// Items awaiting user confirmation (date has passed but not yet confirmed).
  List<OccasionalModel> get pendingConfirmations => occasionalList
      .where((e) =>
          e.isConfirmed == null &&
          e.date.isBefore(DateTime.now().add(const Duration(days: 1))))
      .toList();
}
