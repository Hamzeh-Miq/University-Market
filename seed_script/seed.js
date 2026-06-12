/**
 * UniSooq Data Seeder
 * -------------------
 * Uploads seed photos to Firebase Storage, then creates fake student
 * user profiles and product listings in Firestore.
 *
 * Run once with:  node seed.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ── 1. Initialize Firebase Admin ─────────────────────────────────────────────

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'university-market-2b9d7.firebasestorage.app',
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// ── 2. Photo → Category mapping ──────────────────────────────────────────────

// Maps each photo filename to the category it belongs to and a
// realistic product listing description.
const photoListings = [
  {
    file: 'Arts1.jpg',
    category: 'Arts',
    title: 'Introduction to Fine Arts Textbook',
    description: 'Lightly used Arts & Design textbook. Perfect condition, no highlights.',
    price: 12.0,
    courseCode: 'ART101',
  },
  {
    file: 'Arts2.png',
    category: 'Arts',
    title: 'Art History & Appreciation Guide',
    description: 'Comprehensive guide covering art history from ancient to modern. A few pencil marks.',
    price: 8.5,
    courseCode: 'ART201',
  },
  {
    file: 'Business1.jpg',
    category: 'Business',
    title: 'Principles of Management – 3rd Edition',
    description: 'Management textbook, 3rd edition. Good condition, minor highlighting on chapter 4.',
    price: 15.0,
    courseCode: 'BUS201',
  },
  {
    file: 'Business2.jpg',
    category: 'Business',
    title: 'Marketing Fundamentals Textbook',
    description: 'Marketing textbook used for one semester. Clean copy, no writing inside.',
    price: 18.0,
    courseCode: 'MKT101',
  },
  {
    file: 'Eingineering1.jpg',
    category: 'Engineering',
    title: 'Civil Engineering Drawing Manual',
    description: 'Engineering drawing manual with all diagrams intact. Minimal use.',
    price: 20.0,
    courseCode: 'CE201',
  },
  {
    file: 'Engineering2.jpg',
    category: 'Engineering',
    title: 'Thermodynamics – Engineering Approach',
    description: 'Classic Cengel & Boles thermodynamics book. Well maintained, some sticky notes.',
    price: 25.0,
    courseCode: 'ME301',
  },
  {
    file: 'engineering3.jpg',
    category: 'Engineering',
    title: 'Structural Analysis Reference Book',
    description: 'Structural analysis reference, lightly annotated. Great for exam prep.',
    price: 22.0,
    courseCode: 'CE302',
  },
  {
    file: 'IT1.jpg',
    category: 'IT',
    title: 'Introduction to Programming – Python',
    description: 'Python intro textbook used for one semester. Clean and in great shape.',
    price: 14.0,
    courseCode: 'CS101',
  },
  {
    file: 'IT2.jpg',
    category: 'IT',
    title: 'Data Structures & Algorithms (Java)',
    description: 'Classic data structures book. Some highlights on trees and graphs chapters.',
    price: 20.0,
    courseCode: 'CS201',
  },
  {
    file: 'IT3.jpg',
    category: 'IT',
    title: 'Database Systems – Complete Reference',
    description: 'Database systems textbook covering SQL, normalization & transactions. Like new.',
    price: 17.0,
    courseCode: 'CS301',
  },
  {
    file: 'Nursing.jpg',
    category: 'Nursing',
    title: 'Fundamentals of Nursing Practice',
    description: 'Core nursing textbook. Perfect for first and second year students.',
    price: 18.0,
    courseCode: 'NUR101',
  },
  {
    file: 'Nursing2.jpg',
    category: 'Nursing',
    title: 'Medical-Surgical Nursing – Clinical Guide',
    description: 'Clinical nursing guide with case studies. Some bookmarks inside.',
    price: 22.0,
    courseCode: 'NUR301',
  },
  {
    file: 'dentist.jpg',
    category: 'Dentistry',
    title: 'Oral Anatomy & Physiology Textbook',
    description: 'Dentistry anatomy book in very good condition. Used for one year.',
    price: 30.0,
    courseCode: 'DEN201',
  },
  {
    file: 'dentist2.jpg',
    category: 'Dentistry',
    title: 'Clinical Dental Procedures Manual',
    description: 'Practical dental procedures manual. Clear diagrams and step-by-step guides.',
    price: 25.0,
    courseCode: 'DEN301',
  },
  {
    file: 'house1.jpg',
    category: 'Home Stuff',
    title: 'Desk Lamp – Adjustable LED',
    description: 'LED desk lamp with adjustable brightness. Works perfectly, selling because I graduated.',
    price: 8.0,
    courseCode: null,
  },
  {
    file: 'house2.jpg',
    category: 'Home Stuff',
    title: 'Mini Bookshelf – White Wood',
    description: 'Small 3-tier bookshelf for your dorm room. Easy to assemble and move.',
    price: 12.0,
    courseCode: null,
  },
  {
    file: 'law1.jpg',
    category: 'Law',
    title: 'Introduction to Jordanian Civil Law',
    description: 'Civil law intro textbook. Very important for first year law students.',
    price: 16.0,
    courseCode: 'LAW101',
  },
  {
    file: 'law2.png',
    category: 'Law',
    title: 'Constitutional Law – Theory & Practice',
    description: 'Constitutional law textbook. Good condition, a few underlined paragraphs.',
    price: 19.0,
    courseCode: 'LAW202',
  },
  {
    file: 'law3.jpg',
    category: 'Law',
    title: 'Criminal Law Principles Textbook',
    description: 'Criminal law principles book. Covers Jordanian penal code thoroughly.',
    price: 13.0,
    courseCode: 'LAW301',
  },
  {
    file: 'law4.jpg',
    category: 'Law',
    title: 'Commercial Law & Business Regulations',
    description: 'Comprehensive commercial law textbook covering contracts and corporate law.',
    price: 21.0,
    courseCode: 'LAW401',
  },
  {
    file: 'linguistics 2.jpg',
    category: 'Languages',
    title: 'Applied Linguistics – Language & Society',
    description: 'Linguistics textbook covering sociolinguistics and pragmatics. Clean copy.',
    price: 11.0,
    courseCode: 'LING201',
  },
  {
    file: 'linguistics.jpg',
    category: 'Languages',
    title: 'Introduction to Linguistics',
    description: 'First year linguistics book. Great introduction to phonetics and morphology.',
    price: 10.0,
    courseCode: 'LING101',
  },
  {
    file: 'pharma1.jpg',
    category: 'Pharmaceutics',
    title: 'Pharmacology Principles Textbook',
    description: 'Pharmacology textbook for pharmacy students. Some color-coded notes inside.',
    price: 28.0,
    courseCode: 'PHAR201',
  },
  {
    file: 'pharma2.jpg',
    category: 'Pharmaceutics',
    title: 'Pharmaceutical Chemistry Lab Manual',
    description: 'Lab manual for pharmaceutical chemistry. All experiments well documented.',
    price: 15.0,
    courseCode: 'PHAR301',
  },
  {
    file: 'sharia1.jpg',
    category: 'Sharia',
    title: 'Islamic Jurisprudence – Fiqh Foundations',
    description: 'Foundational Fiqh textbook. Well preserved, clear Arabic text.',
    price: 12.0,
    courseCode: 'SHA101',
  },
  {
    file: 'sharia2.jpg',
    category: 'Sharia',
    title: 'Principles of Islamic Law (Usul al-Fiqh)',
    description: 'Advanced Usul al-Fiqh textbook. Recommended for second year and above.',
    price: 14.0,
    courseCode: 'SHA201',
  },
];

// ── 3. Fake student sellers ───────────────────────────────────────────────────

const fakeSellers = [
  { uid: 'seed_user_001', firstName: 'Rania',   middleName: 'Khaled',  lastName: 'Al-Masri',   phone: '0791234561', rating: 4.8, reviews: 12 },
  { uid: 'seed_user_002', firstName: 'Omar',    middleName: 'Faris',   lastName: 'Sabbagh',    phone: '0792345672', rating: 4.5, reviews: 7  },
  { uid: 'seed_user_003', firstName: 'Lina',    middleName: 'Nabil',   lastName: 'Khoury',     phone: '0793456783', rating: 4.9, reviews: 20 },
  { uid: 'seed_user_004', firstName: 'Ahmad',   middleName: 'Tariq',   lastName: 'Barakat',    phone: '0794567894', rating: 4.2, reviews: 5  },
  { uid: 'seed_user_005', firstName: 'Sara',    middleName: 'Yousef',  lastName: 'Haddad',     phone: '0795678905', rating: 4.7, reviews: 15 },
  { uid: 'seed_user_006', firstName: 'Hamza',   middleName: 'Amer',    lastName: 'Qasim',      phone: '0796789016', rating: 4.3, reviews: 8  },
  { uid: 'seed_user_007', firstName: 'Nour',    middleName: 'Samir',   lastName: 'Tawfiq',     phone: '0797890127', rating: 4.6, reviews: 11 },
  { uid: 'seed_user_008', firstName: 'Faris',   middleName: 'Hassan',  lastName: 'Rimawi',     phone: '0798901238', rating: 4.4, reviews: 6  },
];

// ── 4. Helper: Upload a photo to Firebase Storage ────────────────────────────

async function uploadPhoto(filePath, fileName) {
  const destination = `products/seed_${fileName}`;
  await bucket.upload(filePath, {
    destination,
    metadata: { contentType: fileName.endsWith('.png') ? 'image/png' : 'image/jpeg' },
  });
  const file = bucket.file(destination);
  await file.makePublic();
  return `https://storage.googleapis.com/${bucket.name}/${destination}`;
}

// ── 5. Main seeder ────────────────────────────────────────────────────────────

async function seed() {
  const photosDir = path.join(__dirname, '..', 'seed_photos');
  const university = 'Applied Science Private University';

  console.log('\n🌱 UniSooq Seeder starting...\n');

  // ── 5a. Write fake user profiles to Firestore ─────────────────────────────
  console.log('👤 Creating fake user profiles...');
  const batch = db.batch();
  for (const seller of fakeSellers) {
    const fullName = `${seller.firstName} ${seller.middleName} ${seller.lastName}`;
    const userRef = db.collection('users').doc(seller.uid);
    batch.set(userRef, {
      email: `${seller.firstName.toLowerCase()}.${seller.lastName.toLowerCase()}@students.edu.jo`,
      firstName: seller.firstName,
      middleName: seller.middleName,
      lastName: seller.lastName,
      fullName,
      displayName: seller.firstName,
      phoneNumber: seller.phone,
      university,
      isVerified: true,
      rating: seller.rating,
      reviewCount: seller.reviews,
      createdAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000)
      ),
      role: 'user',
      isSubscribed: true,
      subscriptionExpiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      ),
      subscriptionActivatedAt: admin.firestore.Timestamp.fromDate(new Date()),
      favoriteProductIds: [],
    });
  }
  await batch.commit();
  console.log(`   ✅ Created ${fakeSellers.length} users\n`);

  // ── 5b. Upload photos & create product listings ───────────────────────────
  console.log('📸 Uploading photos and creating listings...\n');

  for (let i = 0; i < photoListings.length; i++) {
    const listing = photoListings[i];
    const filePath = path.join(photosDir, listing.file);

    if (!fs.existsSync(filePath)) {
      console.log(`   ⚠️  Skipping "${listing.file}" – file not found`);
      continue;
    }

    // Pick a seller round-robin
    const seller = fakeSellers[i % fakeSellers.length];

    process.stdout.write(`   [${i + 1}/${photoListings.length}] Uploading ${listing.file}...`);
    let imageUrl;
    try {
      imageUrl = await uploadPhoto(filePath, listing.file);
      process.stdout.write(' ✅\n');
    } catch (err) {
      process.stdout.write(` ❌ (${err.message})\n`);
      continue;
    }

    // Create the product document
    const docRef = db.collection('products').doc();
    const daysAgo = Math.floor(Math.random() * 60); // posted within last 60 days
    const createdAt = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);

    await docRef.set({
      productId: docRef.id,
      sellerId: seller.uid,
      title: listing.title,
      description: listing.description,
      price: listing.price,
      category: listing.category,
      courseCode: listing.courseCode ?? null,
      images: [imageUrl],
      status: 'published', // directly published, no admin approval needed for seed
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      sellerUniversity: university,
    });
  }

  console.log('\n🎉 Seeding complete!');
  console.log(`   • ${fakeSellers.length} fake student accounts created`);
  console.log(`   • ${photoListings.length} product listings created with real photos`);
  console.log('\n   Open your app and check the marketplace! 🚀\n');
  process.exit(0);
}

seed().catch((err) => {
  console.error('\n❌ Seeder failed:', err.message);
  process.exit(1);
});
