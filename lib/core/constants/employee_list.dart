/// CA Global employee roster for the dashboard selector.
class EmployeeList {
  EmployeeList._();

  static const List<String> names = [
    'Mayur Kumar',
    'Sukhwinder Kaur',
    'Amritpal Singh',
    'Rishu Kamboj',
    'Vikas Chand',
    'Simarjeet Singh',
    'Ritu Sharma',
    'Sonia Sethi',
    'Sahil Kohli',
    'Sarprinder Singh',
    'Abhinav Bathla',
    'Nitesh Kumar',
    'Narad Prajapati',
    'Kajal Rani',
    'Anjali',
    'Poonam',
    'Pooja',
    'Shobhit Bansal',
    'Anmol Kumar',
    'Smarpit Singh',
    'Nikita',
    'Sakshi Sharma',
    'Ravneet Kaur',
    'Vineet Kumar',
    'Pratima',
    'Jaichand',
    'Anshul Kumar',
    'Ashima Malhotra',
    'Vikram Singh',
    'Kulbhushan',
    'Tanuj Kumar',
    'Akanksha Choudhary',
    'Sachin Negi',
    'Vivek Chauhan',
    'Sourav Rana',
    'Jatinder',
    'Manisha Rathore',
    'Isha Singh Jamwal',
    'Raju Manjhi',
    'Armaanpreet kaur',
    'Yashpal Thakur',
    'Rajiv Kumar',
    'Gurpreet Singh Sidhu',
    'Arvind Kumar',
    'Sameer Ali',
    'Ketan Garg',
    'Rohit',
    'Abhay',
    'Simran Mehra (WFH)',
    'Rohit Saini',
    'Sanjeev Kumar',
    'Kawaldeep Kaur',
    'Pankaj Kalsi',
  ];

  static List<String> filter(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List<String>.from(names);

    return names.where((name) => name.toLowerCase().contains(trimmed)).toList();
  }
}
