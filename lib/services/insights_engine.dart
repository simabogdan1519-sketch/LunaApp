import '../models/models.dart';
import 'cycle_calculator.dart';

/// Analyzes patterns from user logs and generates personalized insights.
/// "If user felt better after yoga, recommend yoga next time"
class InsightsEngine {

  // ── Pattern analysis ─────────────────────────────────────────────────────────

  /// Find what activities/behaviors correlate with high mood (mood >= 4)
  static List<String> findPositivePatterns(List<DayLog> logs) {
    if (logs.length < 3) return [];
    final highMoodLogs = logs.where((l) => (l.mood ?? 0) >= 4).toList();
    if (highMoodLogs.isEmpty) return [];

    // Count symptom absence on good days
    final symptomCounts = <String, int>{};
    for (final log in highMoodLogs) {
      for (final s in log.symptoms) { symptomCounts[s] = (symptomCounts[s] ?? 0) + 1; }
    }

    // Check notes for keywords
    final positiveKeywords = <String>[];
    final noteKeywords = {
      'yoga': 'Yoga practice', 'walk': 'Walking', 'run': 'Running', 'gym': 'Exercise',
      'sleep': 'Good sleep', 'meditat': 'Meditation', 'water': 'Staying hydrated',
      'healthy': 'Healthy eating', 'salad': 'Healthy eating', 'fruit': 'Healthy eating',
      'friend': 'Time with friends', 'relax': 'Relaxation', 'rest': 'Resting',
      'bath': 'Warm bath', 'tea': 'Herbal tea', 'stretch': 'Stretching',
      'outside': 'Time outdoors', 'nature': 'Time outdoors', 'music': 'Music',
      'book': 'Reading', 'cook': 'Cooking', 'creative': 'Creative activities',
    };

    for (final log in highMoodLogs) {
      if (log.notes != null) {
        final noteLower = log.notes!.toLowerCase();
        for (final kv in noteKeywords.entries) {
          if (noteLower.contains(kv.key) && !positiveKeywords.contains(kv.value)) {
            positiveKeywords.add(kv.value);
          }
        }
      }
    }
    return positiveKeywords;
  }

  /// Find what correlates with low mood (mood <= 2)
  static List<String> findNegativePatterns(List<DayLog> logs) {
    if (logs.length < 3) return [];
    final lowMoodLogs = logs.where((l) => (l.mood ?? 3) <= 2).toList();
    if (lowMoodLogs.isEmpty) return [];
    final patterns = <String>[];
    final highPainOnBadDays = lowMoodLogs.where((l) => (l.pain ?? 0) >= 3).length;
    if (highPainOnBadDays > lowMoodLogs.length * 0.5) patterns.add('high pain');
    final fatigueOnBadDays = lowMoodLogs.where((l) => l.symptoms.any((s) => s.toLowerCase().contains('fatigue'))).length;
    if (fatigueOnBadDays > lowMoodLogs.length * 0.4) patterns.add('fatigue');
    return patterns;
  }

  /// Generate personalized recommendation based on current phase + past patterns
  static List<PersonalInsight> generateInsights(
    List<DayLog> logs, CyclePhase phase, List<CycleEntry> cycles, int dayInCycle
  ) {
    final insights = <PersonalInsight>[];
    final posPatterns = findPositivePatterns(logs);
    final negPatterns = findNegativePatterns(logs);

    // Personal pattern insights (most valuable)
    if (posPatterns.isNotEmpty && logs.length >= 3) {
      final top = posPatterns.take(2).join(' and ');
      insights.add(PersonalInsight(
        emoji: '✨', title: 'Your personal pattern',
        body: 'Based on your logs, you tend to feel better on days with $top. Today might be a good day for it!',
        type: InsightType.personal, priority: 1,
      ));
    }

    if (negPatterns.contains('fatigue') && (phase == CyclePhase.menstrual || phase == CyclePhase.luteal)) {
      insights.add(PersonalInsight(
        emoji: '😴', title: 'Fatigue alert',
        body: 'Your logs show fatigue is common for you in this phase. Plan lighter tasks today and prioritise sleep tonight.',
        type: InsightType.personal, priority: 2,
      ));
    }

    // Phase-specific science insights (large pool, rotated by day)
    final phaseInsights = _phaseInsightPool[phase] ?? [];
    if (phaseInsights.isNotEmpty) {
      final idx = dayInCycle % phaseInsights.length;
      insights.add(phaseInsights[idx]);
    }

    // Cycle regularity insight
    if (cycles.length >= 3) {
      if (!_isCycleRegularLocal(cycles)) {
        insights.add(PersonalInsight(
          emoji: '📊', title: 'Irregular cycles detected',
          body: 'Your last ${cycles.length} cycles show some variability. This is often normal, but worth mentioning at your next check-up.',
          type: InsightType.health, priority: 3,
        ));
      }
    }

    // Low energy advice
    final recentLogs = logs.take(7).toList();
    final avgEnergy = recentLogs.isEmpty ? 3.0 : recentLogs.map((l) => l.energy ?? 3).reduce((a, b) => a + b) / recentLogs.length;
    if (avgEnergy < 2.5 && recentLogs.length >= 3) {
      insights.add(PersonalInsight(
        emoji: '⚡', title: 'Low energy week',
        body: 'Your energy has been low this week. Check your iron levels, sleep quality, and hydration — these are the top 3 causes.',
        type: InsightType.health, priority: 2,
      ));
    }

    insights.sort((a, b) => a.priority.compareTo(b.priority));
    return insights.take(4).toList();
  }

  static bool _isCycleRegularLocal(List<CycleEntry> cycles) {
    final completed = cycles.where((c) => c.endDate != null).toList();
    if (completed.length < 2) return true;
    final lengths = completed.map((c) => c.endDate!.difference(c.startDate).inDays.toDouble()).toList();
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) / lengths.length;
    return variance < 16;
  }

  // ── Large tip pool (60+ tips) ────────────────────────────────────────────────

  static final Map<CyclePhase, List<PersonalInsight>> _phaseInsightPool = {

    CyclePhase.menstrual: [
      _tip('🥬', 'Iron boost', 'You lose 30–80ml of blood during menstruation. Pair iron-rich foods (spinach, lentils, red meat) with vitamin C for up to 3× better absorption.', 'Mayo Clinic'),
      _tip('🍫', 'Dark chocolate is medicine', 'Dark chocolate (70%+ cocoa) contains magnesium which relaxes uterine muscles and can reduce cramping. A square or two is genuinely helpful!', 'NCBI'),
      _tip('🌡️', 'Heat therapy works', 'A 2012 study found that heat patches (40°C) were as effective as ibuprofen for period pain. A warm water bottle on your lower abdomen is legit medicine.', 'BMJ'),
      _tip('💧', 'Hydration & bloating', 'Counterintuitively, drinking MORE water reduces period bloating. Your body retains water when dehydrated. Aim for 2.5L today.', 'ACOG'),
      _tip('🧘', 'Child\'s pose', 'Yoga\'s child\'s pose and supine twist increase blood flow to the pelvis and can reduce cramp intensity within 10 minutes of practice.', 'ACOG'),
      _tip('🚶', 'Light movement', 'Even a 20-minute walk releases endorphins that act as natural pain relievers. You don\'t need intense exercise — a gentle walk genuinely helps.', 'NHS'),
      _tip('🍵', 'Ginger tea', 'A study of 150 women found ginger (250mg capsules 4× daily) was as effective as mefenamic acid for reducing period pain.', 'NCBI Study'),
      _tip('😴', 'Sleep changes', 'Progesterone drop before menstruation disrupts sleep. Body temperature also rises. Keep your room cool and avoid screens 1 hour before bed.', 'Sleep Foundation'),
      _tip('🦠', 'Gut microbiome', 'Estrogen is partly metabolised by gut bacteria. Fermented foods (yogurt, kefir, kimchi) support hormonal balance throughout your entire cycle.', 'Harvard Health'),
      _tip('🩸', 'Colour tells a story', 'Bright red = healthy flow. Dark brown = older blood, normal at start/end. Pink = lighter flow, can indicate low estrogen. Mention changes to your doctor.', 'ACOG'),
    ],

    CyclePhase.follicular: [
      _tip('⚡', 'Estrogen = superpower', 'Rising estrogen boosts memory, verbal fluency, and coordination. This is your cognitively sharpest phase — schedule important meetings, exams, and presentations now.', 'Neuroscience Research'),
      _tip('💪', 'Strength gains', 'Muscles repair faster in the follicular phase due to estrogen\'s anabolic effect. You can push harder in the gym and recover faster this week.', 'Sports Medicine'),
      _tip('🧠', 'Creative peak', 'The right hemisphere of the brain becomes more active in the follicular phase, boosting creative thinking. Great time for brainstorming and artistic work.', 'NCBI'),
      _tip('🫀', 'Cardio performance', 'Estrogen improves cardiovascular efficiency. VO2 max is measurably higher in this phase — your best runs and HIIT sessions are in the follicular phase.', 'British Journal of Sports Medicine'),
      _tip('🌿', 'Seed cycling: flaxseeds', 'Flaxseeds contain lignans that support estrogen metabolism. 1 tbsp ground flaxseeds daily during the follicular phase is a popular (and researched) hormonal support practice.', 'Nutrition Research'),
      _tip('🍳', 'Protein timing', 'Higher muscle protein synthesis in this phase means protein intake is more efficiently used for muscle building. Eggs, Greek yogurt and legumes are ideal.', 'Sports Nutrition'),
      _tip('☀️', 'Light exposure', 'Morning light (10–30 min outside within 1 hour of waking) regulates cortisol rhythm and supports the hormonal cascade of the follicular phase.', 'Circadian Research'),
      _tip('🎯', 'Best week for goals', 'Dopamine sensitivity is higher in follicular phase. New habits stick better. If you want to start something — a workout plan, a new diet, a project — start now.', 'Behavioral Science'),
    ],

    CyclePhase.ovulation: [
      _tip('🌡️', 'BBT rises at ovulation', 'Your basal body temperature rises 0.2–0.5°C after ovulation and stays elevated until your next period. Tracking BBT is 99% accurate for confirming ovulation has occurred.', 'ACOG'),
      _tip('🗣️', 'Communication peak', 'Estrogen and testosterone peak together during ovulation, making you feel more confident, articulate, and persuasive. It\'s a great day for difficult conversations.', 'UCLA Research'),
      _tip('🔬', 'LH surge', 'The LH (luteinizing hormone) surge triggers ovulation 24–36 hours before egg release. Signs include clear, stretchy discharge (like egg whites) and mild mid-cycle cramps.', 'ACOG'),
      _tip('🏃', 'Peak athletic performance', 'Testosterone peaks at ovulation alongside estrogen. Studies show measurable improvements in sprint speed, power, and reaction time this week.', 'Sports Medicine'),
      _tip('🌺', 'Fertile window = 6 days', 'Sperm can survive up to 5 days in the fallopian tubes, and the egg lives 12–24 hours. The fertile window is the 5 days BEFORE ovulation plus the day of ovulation.', 'ACOG'),
      _tip('🧬', 'Immune system shifts', 'Immunity temporarily dips slightly around ovulation — an evolutionary mechanism. Wash hands and avoid sick contacts if you\'re immunocompromised.', 'Immunology Research'),
      _tip('💃', 'Energy peak', 'This is your highest-energy day of the cycle. Many women report feeling their best physically and mentally. Use this energy intentionally.', 'Endocrinology'),
    ],

    CyclePhase.luteal: [
      _tip('🥛', 'Calcium & PMS', 'A landmark study showed 1200mg of calcium daily reduced PMS symptoms — mood swings, bloating, irritability, depression — by up to 48%. Dairy, fortified milks, sardines.', 'NCBI'),
      _tip('🌙', 'Sleep disruption ahead', 'Progesterone breaks down into allopregnanolone, which disrupts deep sleep architecture. Keep bedroom below 18°C, and try magnesium glycinate (200–400mg) before bed.', 'Sleep Research'),
      _tip('🧘', 'Not "too sensitive"', 'Emotional sensitivity in the luteal phase is biological — progesterone amplifies the amygdala\'s response to emotional stimuli. Your feelings are valid and have a physiological cause.', 'Neuroscience'),
      _tip('🍠', 'Complex carbs = serotonin', 'Sweet potatoes, oats, and brown rice boost serotonin production. Cravings for carbs in this phase are your brain\'s way of asking for serotonin. Listen to it wisely.', 'Nutrition Science'),
      _tip('🚶', 'Walk > nap', 'A 30-minute walk in the luteal phase raises serotonin more effectively than a nap. If you\'re tired, a brief walk may actually give you more energy than lying down.', 'Sports Medicine'),
      _tip('🧂', 'Reduce sodium', 'High sodium causes water retention which worsens luteal bloating. Try to reduce processed foods and restaurant meals in the 5 days before your period.', 'ACOG'),
      _tip('🎧', 'Music therapy', 'Research found that listening to 30 minutes of calming music reduces cortisol (stress hormone) by up to 12%. A small but real effect for mood management.', 'PubMed'),
      _tip('🧠', 'Interoceptive phase', 'The luteal brain is more inward-focused and detail-oriented. While not ideal for big social events, it\'s excellent for editing, analysis, and introspective work.', 'Psychology Research'),
      _tip('🫘', 'Magnesium for cramps', 'Magnesium relaxes smooth muscle and reduces prostaglandin production (the cause of cramps). 300mg magnesium glycinate daily for 2 weeks before period shows strong evidence.', 'NCBI'),
      _tip('☕', 'Caffeine & PMS', 'Caffeine constricts blood vessels and can intensify cramps and breast tenderness. Try cutting coffee to 1 cup/day in the week before your period.', 'ACOG'),
    ],

    CyclePhase.unknown: [
      _tip('📅', 'Why track?', 'Cycle tracking reveals patterns in mood, energy, sleep and health that are otherwise invisible. Even 2 months of data gives valuable personal insights.', 'Luna'),
      _tip('🩺', 'Doctor communication', 'Having 3+ months of cycle data makes appointments dramatically more productive. Your doctor can spot hormonal issues much faster with logged data.', 'ACOG'),
      _tip('💜', 'Start simple', 'You don\'t need to track everything at once. Just logging your period start date is already valuable — predictions and insights improve with each cycle.', 'Luna'),
    ],
  };

  static PersonalInsight _tip(String emoji, String title, String body, String source) => PersonalInsight(
    emoji: emoji, title: title, body: body, source: source, type: InsightType.science, priority: 5,
  );

  // ── Notification messages ─────────────────────────────────────────────────────

  static List<NotificationTemplate> getScheduledNotifications(
    List<CycleEntry> cycles, int cycleLen, int periodLen
  ) {
    final notifications = <NotificationTemplate>[];
    if (cycles.isEmpty) return notifications;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final events = CycleCalculator.getUpcomingEvents(cycles, cycleLen, periodLen);

    for (final event in events) {
      switch (event.type) {
        case EventType.period:
          if (event.daysUntil == 2) notifications.add(NotificationTemplate(title: '🩸 Period in 2 days', body: 'Your period is expected in 2 days. Stock up on supplies and plan some self-care.', scheduledFor: event.date.subtract(const Duration(days: 2))));
          if (event.daysUntil == 1) notifications.add(NotificationTemplate(title: '🩸 Period tomorrow', body: 'Tomorrow is your expected period start. Consider gentle plans for tomorrow.', scheduledFor: event.date.subtract(const Duration(days: 1))));
          if (event.daysUntil == 0) notifications.add(NotificationTemplate(title: '🩸 Period expected today', body: 'Your period might start today. Remember to log it when it does!', scheduledFor: today));
          break;
        case EventType.ovulation:
          if (event.daysUntil == 1) notifications.add(NotificationTemplate(title: '🌸 Ovulation tomorrow', body: 'Tomorrow is your predicted ovulation day — your peak energy and fertility day.', scheduledFor: event.date.subtract(const Duration(days: 1))));
          if (event.daysUntil == 0) notifications.add(NotificationTemplate(title: '🌸 Ovulation day!', body: 'Today is your predicted ovulation day. You\'re at peak fertility and energy.', scheduledFor: today));
          break;
        case EventType.fertile:
          if (event.daysUntil == 1) notifications.add(NotificationTemplate(title: '🌺 Fertile window starting tomorrow', body: 'Your fertile window begins tomorrow. Your most fertile days are approaching.', scheduledFor: event.date.subtract(const Duration(days: 1))));
          break;
        default: break;
      }
    }

    return notifications;
  }
}

class PersonalInsight {
  final String emoji, title, body;
  final String? source;
  final InsightType type;
  final int priority;
  PersonalInsight({required this.emoji, required this.title, required this.body, this.source, required this.type, required this.priority});
}

enum InsightType { personal, health, science, reminder }

class NotificationTemplate {
  final String title, body;
  final DateTime scheduledFor;
  NotificationTemplate({required this.title, required this.body, required this.scheduledFor});
}

// Accessor to avoid circular import
