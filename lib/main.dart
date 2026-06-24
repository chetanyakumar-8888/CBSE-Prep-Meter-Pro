import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrepMeterApp());
}

class PrepMeterApp extends StatelessWidget {
  const PrepMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBSE Prep Meter Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: const Color(0xFF4F46E5),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF111736),
        ),
      ),
      home: const ApplicationController(),
    );
  }
}

// ==========================================
// CORE DATA ARCHITECTURE
// ==========================================
class MilestoneTask {
  final String label;
  bool isCompleted;

  MilestoneTask({required this.label, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'label': label, 'isCompleted': isCompleted};
  factory MilestoneTask.fromJson(Map<String, dynamic> json) =>
      MilestoneTask(label: json['label'], isCompleted: json['isCompleted'] ?? false);
}

class PrepChapter {
  final String name;
  final List<MilestoneTask> milestones;

  // Whenever a new PrepChapter is created without explicit milestones, 
  // it automatically generates these 5 default tick boxes.
  PrepChapter({required this.name, List<MilestoneTask>? milestones})
      : milestones = milestones ?? [
          MilestoneTask(label: '📺 Lecture Completed'),
          MilestoneTask(label: '📝 Detailed Notes Written'),
          MilestoneTask(label: '⚡ Short Notes / Formula Sheet'),
          MilestoneTask(label: '📚 NCERT Exercises Solved'),
          MilestoneTask(label: '🎯 Question Bank & PYQs Done'),
        ];

  double get completionPercentage {
    if (milestones.isEmpty) return 0.0;
    int completed = milestones.where((m) => m.isCompleted).length;
    return (completed / milestones.length) * 100;
  }

  int get completedCount => milestones.where((m) => m.isCompleted).length;

  Map<String, dynamic> toJson() => {
        'name': name,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory PrepChapter.fromJson(Map<String, dynamic> json) => PrepChapter(
        name: json['name'],
        milestones: (json['milestones'] as List)
            .map((m) => MilestoneTask.fromJson(m))
            .toList(),
      );
}

class PrepSubject {
  final String name;
  List<PrepChapter> chapters;

  PrepSubject({required this.name, required this.chapters});

  double get masteryPercentage {
    if (chapters.isEmpty) return 0.0;
    double totalProgress = chapters.fold(0.0, (sum, ch) => sum + ch.completionPercentage);
    return totalProgress / chapters.length;
  }

  int get totalTasksCount => chapters.length * 5;
  int get completedTasksCount => chapters.fold(0, (sum, ch) => sum + ch.completedCount);

  Map<String, dynamic> toJson() => {
        'name': name,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory PrepSubject.fromJson(Map<String, dynamic> json) => PrepSubject(
        name: json['name'],
        chapters: (json['chapters'] as List)
            .map((c) => PrepChapter.fromJson(c))
            .toList(),
      );
}

// ==========================================
// MAIN STATE STORAGE & NAVIGATION ENGINE
// ==========================================
class ApplicationController extends StatefulWidget {
  const ApplicationController({super.key});

  @override
  State<ApplicationController> createState() => _ApplicationControllerState();
}

class _ApplicationControllerState extends State<ApplicationController> {
  bool _isLoading = true;
  bool _isOnboarded = false;
  String _selectedClass = 'Class 10';
  String _selectedStream = 'Science - PCM';
  List<PrepSubject> _userSubjects = [];
  PrepSubject? _activeSubject;

  Color getProgressStateColor(double percentage) {
    if (percentage <= 20) return const Color(0xFFEF4444);
    if (percentage <= 40) return const Color(0xFFF59E0B);
    if (percentage <= 60) return const Color(0xFF10B981);
    if (percentage <= 80) return const Color(0xFF0D9488);
    return const Color(0xFF22C55E);
  }

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('cbse_granular_prepmeter_v4');
      if (dataString != null) {
        final Map<String, dynamic> decoded = jsonDecode(dataString);
        setState(() {
          _selectedClass = decoded['class'] ?? 'Class 10';
          _selectedStream = decoded['stream'] ?? '';
          _userSubjects = (decoded['subjects'] as List)
              .map((s) => PrepSubject.fromJson(s))
              .toList();
          _isOnboarded = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileData = {
      'class': _selectedClass,
      'stream': _selectedStream,
      'subjects': _userSubjects.map((s) => s.toJson()).toList(),
    };
    await prefs.setString('cbse_granular_prepmeter_v4', jsonEncode(profileData));
  }

  void _generateSyllabusWorkspace(List<String> chosenNames) {
    // ==============================================================
    // THE ULTIMATE CBSE MASTER SYLLABUS DICTIONARY (RATIONALIZED)
    // ==============================================================
    Map<String, Map<String, List<String>>> masterSyllabus = {
      'Class 6': {
        'Mathematics': ['Knowing Our Numbers', 'Whole Numbers', 'Playing with Numbers', 'Basic Geometrical Ideas', 'Understanding Elementary Shapes', 'Integers', 'Fractions', 'Decimals', 'Data Handling', 'Mensuration', 'Algebra', 'Ratio and Proportion', 'Symmetry', 'Practical Geometry'],
        'Science': ['Components of Food', 'Sorting Materials into Groups', 'Separation of Substances', 'Getting to Know Plants', 'Body Movements', 'The Living Organisms', 'Motion and Measurement', 'Light, Shadows and Reflections', 'Electricity and Circuits', 'Fun with Magnets', 'Air Around Us'],
        'Social Science': ['What, Where, How and When?', 'From Gathering to Growing Food', 'In the Earliest Cities', 'What Books and Burials Tell Us', 'Kingdoms, Kings and an Early Republic', 'New Questions and Ideas', 'Ashoka, The Emperor Who Gave Up War', 'Vital Villages, Thriving Towns', 'Traders, Kings and Pilgrims', 'New Empires and Kingdoms', 'Buildings, Paintings and Books', 'The Earth in the Solar System', 'Globe: Latitudes and Longitudes', 'Motions of the Earth', 'Maps', 'Major Domains of the Earth', 'Our Country - India', 'Understanding Diversity', 'Diversity and Discrimination', 'What is Government?', 'Panchayati Raj', 'Rural Administration', 'Urban Administration', 'Rural Livelihoods', 'Urban Livelihoods'],
        'English': ['Who Did Patrick’s Homework?', 'How the Dog Found Himself a New Master!', 'Taro’s Reward', 'An Indian – American Woman in Space', 'A Different Kind of School', 'Who I Am', 'Fair Play', 'A Game of Chance', 'Desert Animals', 'The Banyan Tree'],
        'Hindi': ['वह चिड़िया जो', 'बचपन', 'नादान दोस्त', 'चाँद से थोड़ी-सी गप्पें', 'अक्षरों का महत्व', 'पार नज़र के', 'साथी हाथ बढ़ाना', 'ऐसे-ऐसे', 'टिकट अलबम', 'झाँसी की रानी', 'जो देखकर भी नहीं देखते', 'संसार पुस्तक है', 'मैं सबसे छोटी होऊँ', 'लोकगीत', 'नौकर', 'वन के मार्ग में', 'साँस-साँस में बाँस']
      },
      'Class 7': {
        'Mathematics': ['Integers', 'Fractions and Decimals', 'Data Handling', 'Simple Equations', 'Lines and Angles', 'The Triangle and its Properties', 'Comparing Quantities', 'Rational Numbers', 'Perimeter and Area', 'Algebraic Expressions', 'Exponents and Powers', 'Symmetry', 'Visualising Solid Shapes'],
        'Science': ['Nutrition in Plants', 'Nutrition in Animals', 'Heat', 'Acids, Bases and Salts', 'Physical and Chemical Changes', 'Respiration in Organisms', 'Transportation in Animals and Plants', 'Reproduction in Plants', 'Motion and Time', 'Electric Current and its Effects', 'Light', 'Forests: Our Lifeline', 'Wastewater Story'],
        'Social Science': ['Tracing Changes Through a Thousand Years', 'New Kings and Kingdoms', 'The Delhi Sultans', 'The Mughal Empire', 'Tribes, Nomads and Settled Communities', 'Devotional Paths to the Divine', 'The Making of Regional Cultures', 'Eighteenth-Century Political Formations', 'Environment', 'Inside Our Earth', 'Our Changing Earth', 'Air', 'Water', 'Human Environment Interactions', 'Life in the Deserts', 'On Equality', 'Role of the Government in Health', 'How the State Government Works', 'Growing up as Boys and Girls', 'Women Change the World', 'Understanding Media', 'Markets Around Us', 'A Shirt in the Market'],
        'English': ['Three Questions', 'A Gift of Chappals', 'Gopal and the Hilsa Fish', 'The Ashes That Made Trees Bloom', 'Quality', 'Expert Detectives', 'The Invention of Vita-Wonk', 'Fire: Friend and Foe', 'A Bicycle in Good Repair', 'The Story of Cricket'],
        'Hindi': ['हम पंछी उन्मुक्त गगन के', 'दादी माँ', 'हिमालय की बेटियां', 'कठपुतली', 'मिठाईवाला', 'रक्त और हमारा शरीर', 'पापा खो गए', 'शाम-एक किसान', 'चिड़िया की बच्ची', 'अपूर्व अनुभव', 'रहीम के दोहे', 'कंचा', 'एक तिनका', 'खानपान की बदलती तस्वीर', 'नीलकंठ', 'भोर और बरखा', 'वीर कुंवर सिंह', 'संघर्ष के कारन मैं तुनुकमिज़ाज हो गया', 'आश्रम का अनुमानित व्यय']
      },
      'Class 8': {
        'Mathematics': ['Rational Numbers', 'Linear Equations in One Variable', 'Understanding Quadrilaterals', 'Data Handling', 'Squares and Square Roots', 'Cubes and Cube Roots', 'Comparing Quantities', 'Algebraic Expressions and Identities', 'Mensuration', 'Exponents and Powers', 'Direct and Inverse Proportions', 'Factorisation', 'Introduction to Graphs'],
        'Science': ['Crop Production and Management', 'Microorganisms: Friend and Foe', 'Coal and Petroleum', 'Combustion and Flame', 'Conservation of Plants and Animals', 'Reproduction in Animals', 'Reaching the Age of Adolescence', 'Force and Pressure', 'Friction', 'Sound', 'Chemical Effects of Electric Current', 'Some Natural Phenomena', 'Light'],
        'Social Science': ['How, When and Where', 'From Trade to Territory', 'Ruling the Countryside', 'Tribals, Dikus and the Vision of a Golden Age', 'When People Rebel 1857 and After', 'Civilising the "Native", Educating the Nation', 'Women, Caste and Reform', 'The Making of the National Movement', 'Resources', 'Land, Soil, Water, Natural Vegetation', 'Agriculture', 'Industries', 'Human Resources', 'The Indian Constitution', 'Understanding Secularism', 'Parliament and the Making of Laws', 'Judiciary', 'Understanding Marginalisation', 'Confronting Marginalisation', 'Public Facilities', 'Law and Social Justice'],
        'English': ['The Best Christmas Present in the World', 'The Tsunami', 'Glimpses of the Past', 'Bepin Choudhury’s Lapse of Memory', 'The Summit Within', 'This is Jody’s Fawn', 'A Visit to Cambridge', 'A Short Monsoon Diary', 'The Great Stone Face - I', 'The Great Stone Face - II'],
        'Hindi': ['ध्वनि', 'लाख की चूड़ियाँ', 'बस की यात्रा', 'दीवानों की हस्ती', 'चिट्ठियों की अनूठी दुनिया', 'भगवान के डाकिए', 'क्या निराश हुआ जाए', 'यह सबसे कठिन समय नहीं', 'कबीर की साखियाँ', 'कामचोर', 'जब सिनेमा ने बोलना सीखा', 'सुदामा चरित', 'जहाँ पहिया है', 'अकबरी लोटा', 'सूर के पद', 'पानी की कहानी', 'बाज और साँप', 'टोपी']
      },
      'Class 9': {
        'Mathematics': ['Number Systems', 'Polynomials', 'Coordinate Geometry', 'Linear Equations in Two Variables', 'Introduction to Euclid’s Geometry', 'Lines and Angles', 'Triangles', 'Quadrilaterals', 'Circles', 'Heron’s Formula', 'Surface Areas and Volumes', 'Statistics'],
        'Science': ['Matter in Our Surroundings', 'Is Matter Around Us Pure', 'Atoms and Molecules', 'Structure of the Atom', 'The Fundamental Unit of Life', 'Tissues', 'Motion', 'Force and Laws of Motion', 'Gravitation', 'Work and Energy', 'Sound', 'Improvement in Food Resources'],
        'Social Science': ['The French Revolution', 'Socialism in Europe and the Russian Revolution', 'Nazism and the Rise of Hitler', 'Forest Society and Colonialism', 'Pastoralists in the Modern World', 'India - Size and Location', 'Physical Features of India', 'Drainage', 'Climate', 'Natural Vegetation and Wildlife', 'Population', 'What is Democracy? Why Democracy?', 'Constitutional Design', 'Electoral Politics', 'Working of Institutions', 'Democratic Rights', 'The Story of Village Palampur', 'People as Resource', 'Poverty as a Challenge', 'Food Security in India'],
        'English': ['The Fun They Had', 'The Sound of Music', 'The Little Girl', 'A Truly Beautiful Mind', 'The Snake and the Mirror', 'My Childhood', 'Reach for the Top', 'Kathmandu', 'If I Were You', 'The Lost Child', 'The Adventures of Toto', 'Iswaran the Storyteller', 'In the Kingdom of Fools', 'The Happy Prince', 'Weathering the Storm in Ersama', 'The Last Leaf', 'A House is Not a Home', 'The Beggar'],
        'Hindi': ['दो बैलों की कथा', 'ल्हासा की ओर', 'उपभोक्तावाद की संस्कृति', 'साँवले सपनों की याद', 'प्रेमचंद के फटे जूते', 'मेरे बचपन के दिन', 'साखियाँ एवं सबद', 'वाख', 'सवैये', 'कैदी और कोकिला', 'ग्राम श्री', 'मेघ आए', 'बच्चे काम पर जा रहे हैं', 'इस जल प्रलय में', 'मेरे संग की औरतें', 'रीढ़ की हड्डी']
      },
      'Class 10': {
        'Mathematics': ['Real Numbers', 'Polynomials', 'Pair of Linear Equations in Two Variables', 'Quadratic Equations', 'Arithmetic Progressions', 'Triangles', 'Coordinate Geometry', 'Introduction to Trigonometry', 'Some Applications of Trigonometry', 'Circles', 'Areas Related to Circles', 'Surface Areas and Volumes', 'Statistics', 'Probability'],
        'Science': ['Chemical Reactions and Equations', 'Acids, Bases and Salts', 'Metals and Non-metals', 'Carbon and its Compounds', 'Life Processes', 'Control and Coordination', 'How do Organisms Reproduce?', 'Heredity', 'Light – Reflection and Refraction', 'The Human Eye and the Colourful World', 'Electricity', 'Magnetic Effects of Electric Current', 'Our Environment'],
        'Social Science': ['The Rise of Nationalism in Europe', 'Nationalism in India', 'The Making of a Global World', 'The Age of Industrialisation', 'Print Culture and the Modern World', 'Resources and Development', 'Forest and Wildlife Resources', 'Water Resources', 'Agriculture', 'Minerals and Energy Resources', 'Manufacturing Industries', 'Lifelines of National Economy', 'Power Sharing', 'Federalism', 'Gender, Religion and Caste', 'Political Parties', 'Outcomes of Democracy', 'Development', 'Sectors of the Indian Economy', 'Money and Credit', 'Globalisation and the Indian Economy'],
        'English': ['A Letter to God', 'Nelson Mandela: Long Walk to Freedom', 'Two Stories about Flying', 'From the Diary of Anne Frank', 'Glimpses of India', 'Mijbil the Otter', 'Madam Rides the Bus', 'The Sermon at Benares', 'The Proposal', 'A Triumph of Surgery', 'The Thief\'s Story', 'The Midnight Visitor', 'A Question of Trust', 'Footprints without Feet', 'The Making of a Scientist', 'The Necklace', 'Bholi', 'The Book That Saved the Earth'],
        'Hindi': ['सूरदास के पद', 'राम-लक्ष्मण-परशुराम संवाद', 'उत्साह, अट नहीं रही है', 'यह दंतुरित मुसकान, फसल', 'संगतकार', 'नेताजी का चश्मा', 'बालगोबिन भगत', 'लखनवी अंदाज़', 'एक कहानी यह भी', 'नौबतखाने में इबादत', 'संस्कृति', 'माता का अँचल', 'साना-साना हाथ जोड़ि', 'मैं क्यों लिखता हूँ?']
      },
      'Class 11': {
        'Physics': ['Units and Measurements', 'Motion in a Straight Line', 'Motion in a Plane', 'Laws of Motion', 'Work, Energy and Power', 'System of Particles and Rotational Motion', 'Gravitation', 'Mechanical Properties of Solids', 'Mechanical Properties of Fluids', 'Thermal Properties of Matter', 'Thermodynamics', 'Kinetic Theory', 'Oscillations', 'Waves'],
        'Chemistry': ['Some Basic Concepts of Chemistry', 'Structure of Atom', 'Classification of Elements and Periodicity', 'Chemical Bonding and Molecular Structure', 'Thermodynamics', 'Equilibrium', 'Redox Reactions', 'Organic Chemistry: Some Basic Principles', 'Hydrocarbons'],
        'Mathematics': ['Sets', 'Relations and Functions', 'Trigonometric Functions', 'Complex Numbers and Quadratic Equations', 'Linear Inequalities', 'Permutations and Combinations', 'Binomial Theorem', 'Sequences and Series', 'Straight Lines', 'Conic Sections', 'Introduction to Three Dimensional Geometry', 'Limits and Derivatives', 'Statistics', 'Probability'],
        'Biology': ['The Living World', 'Biological Classification', 'Plant Kingdom', 'Animal Kingdom', 'Morphology of Flowering Plants', 'Anatomy of Flowering Plants', 'Structural Organisation in Animals', 'Cell: The Unit of Life', 'Biomolecules', 'Cell Cycle and Cell Division', 'Photosynthesis in Higher Plants', 'Respiration in Plants', 'Plant Growth and Development', 'Breathing and Exchange of Gases', 'Body Fluids and Circulation', 'Excretory Products and their Elimination', 'Locomotion and Movement', 'Neural Control and Coordination', 'Chemical Coordination and Integration'],
        'Coding / CS': ['Computer System Overview', 'Data Representation', 'Boolean Logic', 'Insight into Program Execution', 'Python Basics', 'Control Structures', 'Functions', 'Strings', 'Lists', 'Tuples', 'Dictionaries', 'Cyber Safety', 'Online Access and Computer Security', 'Society, Law and Ethics'],
        'Physical Education': ['Changing Trends & Career in Physical Education', 'Olympism', 'Yoga', 'Physical Education & Sports for CWSN', 'Physical Fitness, Health and Wellness', 'Test, Measurement & Evaluation', 'Fundamentals of Anatomy, Physiology', 'Fundamentals of Kinesiology and Biomechanics', 'Psychology & Sports', 'Training and Doping in Sports'],
        'English': ['The Portrait of a Lady', 'We’re Not Afraid to Die', 'Discovering Tut', 'The Adventure', 'Silk Road', 'A Photograph', 'The Laburnum Top', 'The Voice of the Rain', 'Childhood', 'Father to Son', 'The Summer of the Beautiful White Horse', 'The Address', 'Mother’s Day', 'Birth', 'The Tale of Melon City']
      },
      'Class 12': {
        'Physics': ['Electric Charges and Fields', 'Electrostatic Potential and Capacitance', 'Current Electricity', 'Moving Charges and Magnetism', 'Magnetism and Matter', 'Electromagnetic Induction', 'Alternating Current', 'Electromagnetic Waves', 'Ray Optics and Optical Instruments', 'Wave Optics', 'Dual Nature of Radiation and Matter', 'Atoms', 'Nuclei', 'Semiconductor Electronics'],
        'Chemistry': ['Solutions', 'Electrochemistry', 'Chemical Kinetics', 'The d- and f-Block Elements', 'Coordination Compounds', 'Haloalkanes and Haloarenes', 'Alcohols, Phenols and Ethers', 'Aldehydes, Ketones and Carboxylic Acids', 'Amines', 'Biomolecules'],
        'Mathematics': ['Relations and Functions', 'Inverse Trigonometric Functions', 'Matrices', 'Determinants', 'Continuity and Differentiability', 'Application of Derivatives', 'Integrals', 'Application of Integrals', 'Differential Equations', 'Vector Algebra', 'Three Dimensional Geometry', 'Linear Programming', 'Probability'],
        'Biology': ['Sexual Reproduction in Flowering Plants', 'Human Reproduction', 'Reproductive Health', 'Principles of Inheritance and Variation', 'Molecular Basis of Inheritance', 'Evolution', 'Human Health and Disease', 'Microbes in Human Welfare', 'Biotechnology: Principles and Processes', 'Biotechnology and its Applications', 'Organisms and Populations', 'Ecosystem', 'Biodiversity and Conservation'],
        'Coding / CS': ['Review of Python Basics', 'Functions', 'File Handling (Text, Binary, CSV)', 'Data Structures (Stack)', 'Computer Networks', 'Database Management', 'SQL Queries', 'Interface Python with SQL'],
        'Physical Education': ['Management of Sporting Events', 'Children & Women in Sports', 'Yoga as Preventive Measure', 'Physical Education & Sports for CWSN', 'Sports & Nutrition', 'Test & Measurement in Sports', 'Physiology & Injuries in Sports', 'Biomechanics & Sports', 'Psychology & Sports', 'Training in Sports'],
        'English': ['The Last Lesson', 'Lost Spring', 'Deep Water', 'The Rattrap', 'Indigo', 'Poets and Pancakes', 'The Interview', 'Going Places', 'My Mother at Sixty-Six', 'Keeping Quiet', 'A Thing of Beauty', 'A Roadside Stand', 'Aunt Jennifer\'s Tigers', 'The Third Level', 'The Tiger King', 'Journey to the End of the Earth', 'The Enemy', 'On the Face of It', 'Memories of Childhood']
      }
    };

    // Grab the relevant syllabus map for the selected class, or default to Class 10.
    Map<String, List<String>> targetSource = masterSyllabus[_selectedClass] ?? masterSyllabus['Class 10']!;

    setState(() {
      _userSubjects = chosenNames.map((name) {
        // If the subject exists in the map, use it. Otherwise, create a blank starter chapter.
        List<String> chapters = targetSource[name] ?? ['Chapter 1: Conceptual Core Foundations'];
        return PrepSubject(
          name: name,
          chapters: chapters.map((title) => PrepChapter(name: title)).toList(),
        );
      }).toList();
      _isOnboarded = true;
    });
    _saveLocalProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))));
    }

    if (!_isOnboarded) {
      return OnboardingWizard(
        selectedClass: _selectedClass,
        selectedStream: _selectedStream,
        onClassChanged: (v) => setState(() => _selectedClass = v),
        onStreamChanged: (v) => setState(() => _selectedStream = v),
        onComplete: (subjects) => _generateSyllabusWorkspace(subjects),
      );
    }

    if (_activeSubject != null) {
      return SubjectDetailsScreen(
        subject: _activeSubject!,
        colorEvaluator: getProgressStateColor,
        onBack: () {
          setState(() => _activeSubject = null);
          _saveLocalProfile();
        },
        onStateUpdated: () {
          setState(() {});
          _saveLocalProfile();
        },
      );
    }

    return DashboardScreen(
      selectedClass: _selectedClass,
      subjects: _userSubjects,
      colorEvaluator: getProgressStateColor,
      onSubjectSelected: (sub) => setState(() => _activeSubject = sub),
      onReset: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cbse_granular_prepmeter_v4');
        setState(() {
          _isOnboarded = false;
          _userSubjects.clear();
        });
      },
    );
  }
}

// ==========================================
// ONBOARDING WIZARD
// ==========================================
class OnboardingWizard extends StatefulWidget {
  final String selectedClass;
  final String selectedStream;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onStreamChanged;
  final ValueChanged<List<String>> onComplete;

  const OnboardingWizard({
    super.key,
    required this.selectedClass,
    required this.selectedStream,
    required this.onClassChanged,
    required this.onStreamChanged,
    required this.onComplete,
  });

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int _step = 1;
  List<String> _currentPool = [];
  final Map<String, bool> _selectionMatrix = {};
  final TextEditingController _customSubjectController = TextEditingController();

  void _buildContextualPool() {
    int currentClass = int.parse(widget.selectedClass.split(' ')[1]);
    _selectionMatrix.clear();

    if (currentClass <= 10) {
      _currentPool = ['Mathematics', 'Science', 'Social Science', 'English', 'Hindi'];
    } else {
      if (widget.selectedStream.contains('PCM')) {
        _currentPool = ['Physics', 'Chemistry', 'Mathematics', 'Coding / CS', 'Physical Education', 'English'];
      } else if (widget.selectedStream.contains('PCB')) {
        _currentPool = ['Physics', 'Chemistry', 'Biology', 'Physical Education', 'English'];
      } else {
        _currentPool = ['Mathematics', 'English', 'Physical Education'];
      }
    }

    for (var item in _currentPool) {
      _selectionMatrix[item] = true; 
    }
  }

  @override
  void dispose() {
    _customSubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentClass = int.parse(widget.selectedClass.split(' ')[1]);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("PREP METER SYSTEM CONFIGURATION • STEP $_step OF 3",
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 1
                      ? _buildClassSetup()
                      : _step == 2 && currentClass >= 11
                          ? _buildStreamSetup()
                          : _buildSubjectCustomizer(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_step == 1) {
                    if (currentClass < 11) {
                      _buildContextualPool();
                      setState(() => _step = 3);
                    } else {
                      setState(() => _step = 2);
                    }
                  } else if (_step == 2) {
                    _buildContextualPool();
                    setState(() => _step = 3);
                  } else {
                    List<String> confirmed = _selectionMatrix.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    widget.onComplete(confirmed);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_step == 3 ? "GENERATE MY PREP METER" : "CONTINUE"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Your Class", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text("Filters standard syllabus streams accurately.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: widget.selectedClass,
          dropdownColor: const Color(0xFF111736),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => widget.onClassChanged(v!),
        ),
      ],
    );
  }

  Widget _buildStreamSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Academic Stream", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text("Isolates higher secondary course maps.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: widget.selectedStream,
          dropdownColor: const Color(0xFF111736),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ['Science - PCM', 'Science - PCB', 'Commerce', 'Humanities/Arts']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => widget.onStreamChanged(v!),
        ),
      ],
    );
  }

  Widget _buildSubjectCustomizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Active Subjects", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text("Uncheck unwanted fields or manually append targets below.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectionMatrix.length,
          itemBuilder: (context, i) {
            String subName = _selectionMatrix.keys.elementAt(i);
            return CheckboxListTile(
              title: Text(subName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              value: _selectionMatrix[subName],
              activeColor: const Color(0xFFFFD700),
              checkColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _selectionMatrix[subName] = val!),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSubjectController,
                decoration: const InputDecoration(
                  hintText: "Add custom textbook/subject...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: Color(0xFFFFD700), size: 30),
              onPressed: () {
                if (_customSubjectController.text.isNotEmpty) {
                  setState(() => _selectionMatrix[_customSubjectController.text] = true);
                  _customSubjectController.clear();
                }
              },
            )
          ],
        )
      ],
    );
  }
}

// ==========================================
// MOBILE RESPONSIBLE LIST-DRIVEN DASHBOARD
// ==========================================
class DashboardScreen extends StatelessWidget {
  final String selectedClass;
  final List<PrepSubject> subjects;
  final Color Function(double) colorEvaluator;
  final ValueChanged<PrepSubject> onSubjectSelected;
  final VoidCallback onReset;

  const DashboardScreen({
    super.key,
    required this.selectedClass,
    required this.subjects,
    required this.colorEvaluator,
    required this.onSubjectSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    int runningTotalTasks = subjects.fold(0, (sum, sub) => sum + sub.totalTasksCount);
    int runningCompletedTasks = subjects.fold(0, (sum, sub) => sum + sub.completedTasksCount);
    double macroCompletion = runningTotalTasks == 0 ? 0.0 : (runningCompletedTasks / runningTotalTasks) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('🎯 $selectedClass Metrics', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: "Reset Setup Profile",
            onPressed: onReset,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF111736),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      const Text("AGGREGATE PREP LEVEL (ALL SUBJECTS)",
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: macroCompletion / 100),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, val, child) => CircularProgressIndicator(
                                value: val,
                                strokeWidth: 10,
                                backgroundColor: Colors.white10,
                                color: colorEvaluator(macroCompletion),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${macroCompletion.toStringAsFixed(1)}%",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text("$runningCompletedTasks/$runningTotalTasks Ticks",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Your Textbook Trackers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Expanded(
                child: subjects.isEmpty
                    ? const Center(child: Text("No tracking profiles loaded.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, idx) {
                          final sub = subjects[idx];
                          double masteryPercent = sub.masteryPercentage;
                          return Card(
                            color: const Color(0xFF111736),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => onSubjectSelected(sub),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(sub.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                        Text("${masteryPercent.toStringAsFixed(1)}%",
                                            style: TextStyle(color: colorEvaluator(masteryPercent), fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text("${sub.completedTasksCount} of ${sub.totalTasksCount} Explicit Checklist Ticks",
                                        style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: masteryPercent / 100,
                                        backgroundColor: Colors.white10,
                                        color: colorEvaluator(masteryPercent),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WORKSPACE: COMPLETE DYNAMIC CHECKS VIEW
// ==========================================
class SubjectDetailsScreen extends StatefulWidget {
  final PrepSubject subject;
  final Color Function(double) colorEvaluator;
  final VoidCallback onBack;
  final VoidCallback onStateUpdated;

  const SubjectDetailsScreen({
    super.key,
    required this.subject,
    required this.colorEvaluator,
    required this.onBack,
    required this.onStateUpdated,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  final TextEditingController _chapterController = TextEditingController();

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: Colors.white.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.25), width: 1),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 8),
                          Text("PREP LEVEL CHECKLIST LEGEND METRICS", 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("• 20% Complete = Lecture Done (Base Coverage)\n"
                          "• 40% Complete = Comprehensive Notes Written & Logged\n"
                          "• 60% Complete = High-Yield Formula/Short Sheet Constructed\n"
                          "• 80% Complete = Standard Textbook/NCERT Solutions Mastered\n"
                          "• 100% Complete = Exam Ready (Question Bank & Board PYQs Done)",
                          style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chapterController,
                      decoration: InputDecoration(
                        hintText: "Add customized topic/chapter...",
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF111736),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_chapterController.text.isNotEmpty) {
                        setState(() {
                          // Note: the PrepChapter model automatically generates the 5 tickboxes internally!
                          widget.subject.chapters.add(PrepChapter(name: _chapterController.text));
                          _chapterController.clear();
                        });
                        widget.onStateUpdated();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.subject.chapters.length,
                  itemBuilder: (context, idx) {
                    final ch = widget.subject.chapters[idx];
                    double chapterProgress = ch.completionPercentage;
                    return Card(
                      color: const Color(0xFF111736),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(ch.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.colorEvaluator(chapterProgress).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text("${chapterProgress.toStringAsFixed(0)}%",
                                      style: TextStyle(color: widget.colorEvaluator(chapterProgress), fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("${ch.completedCount} of 5 Milestones Logged", style: const TextStyle(fontSize: 11, color: Colors.white38)),
                            const Divider(color: Colors.white10, height: 16),
                            Column(
                              children: ch.milestones.map<Widget>((m) {
                                return CheckboxListTile(
                                  // Fixed the whiteEE typo right here -> Colors.white70
                                  title: Text(m.label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                  value: m.isCompleted,
                                  activeColor: widget.colorEvaluator(chapterProgress),
                                  checkColor: Colors.black,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (val) {
                                    setState(() {
                                      m.isCompleted = val!;
                                    });
                                    widget.onStateUpdated(); 
                                  },
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}