enum CoachStarFilter {
  all,
  starred,
  notStarred;

  String get label => switch (this) {
        CoachStarFilter.all => 'All words',
        CoachStarFilter.starred => 'Starred',
        CoachStarFilter.notStarred => 'Not starred',
      };
}
