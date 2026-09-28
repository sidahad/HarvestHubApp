const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

const outputPath = path.join(__dirname, 'HarvestHub_Additional_Functionality_Documentation.pdf');

// Exact 3-page document with zero auto-page triggers
const doc = new PDFDocument({
  size: 'A4',
  margins: { top: 0, bottom: 0, left: 0, right: 0 },
  autoFirstPage: false,
});

const writeStream = fs.createWriteStream(outputPath);
doc.pipe(writeStream);

function renderPageFrame(pageNum, isFirstPage = false) {
  doc.addPage();
  
  // Top Header Banner
  doc.save();
  doc.rect(0, 0, doc.page.width, 58).fill('#0E2619');
  doc.fillColor('#A1C68A').fontSize(8.5).font('Helvetica-Bold').text('HARVESTHUB // eGreen Basket  •  Official Project Documentation', 35, 13);
  
  if (isFirstPage) {
    doc.fillColor('#F0F5F1').fontSize(13.5).font('Helvetica-Bold').text('09. Additional Functionality & Value-Added Features', 35, 25);
    doc.fillColor('#88AB75').fontSize(8).font('Helvetica').text('Comprehensive Beyond-SRS Engineering Report • HarvestHub v2.0', 35, 41);
  } else {
    doc.fillColor('#F0F5F1').fontSize(13.5).font('Helvetica-Bold').text('Section 09: Additional Functionality (Beyond SRS)', 35, 25);
    doc.fillColor('#88AB75').fontSize(8).font('Helvetica').text('Continuous Feature Specifications & Implementation Details', 35, 41);
  }

  // Footer
  doc.rect(35, doc.page.height - 24, doc.page.width - 70, 0.6).fill('#C2D6C8');
  doc.fillColor('#6A8774').fontSize(7.5).font('Helvetica')
     .text('HarvestHub • Cross-Platform Mobile Application • Theme: eGreen Basket', 35, doc.page.height - 18, { lineBreak: false });
  doc.fillColor('#6A8774').fontSize(7.5).font('Helvetica-Bold')
     .text(`Page ${pageNum} of 3`, doc.page.width - 90, doc.page.height - 18, { width: 55, align: 'right', lineBreak: false });

  doc.restore();
}

function renderSectionHeader(y, title) {
  doc.save();
  doc.rect(35, y, doc.page.width - 70, 16).fill('#133824');
  doc.fillColor('#F0F5F1').fontSize(8.5).font('Helvetica-Bold').text(title, 42, y + 4, { lineBreak: false });
  doc.restore();
  return y + 22;
}

function renderFeatureItem(y, id, title, desc) {
  doc.save();
  // Badge
  doc.roundedRect(35, y, 38, 13, 2.5).fill('#88AB75');
  doc.fillColor('#0D1A13').fontSize(7.2).font('Helvetica-Bold').text(id, 35, y + 3, { width: 38, align: 'center', lineBreak: false });
  
  // Title
  doc.fillColor('#0E3621').fontSize(8.8).font('Helvetica-Bold').text(title, 78, y, { lineBreak: false });
  
  // Description
  doc.fillColor('#334D3D').fontSize(7.6).font('Helvetica').text(desc, 78, y + 12, {
    width: doc.page.width - 116,
    align: 'justify',
    lineGap: 1.1,
    lineBreak: true
  });
  
  const nextY = doc.y + 6;
  doc.restore();
  return nextY;
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 1
// ══════════════════════════════════════════════════════════════════════════════
renderPageFrame(1, true);

// Executive Box
let curY = 68;
doc.save();
doc.roundedRect(35, curY, doc.page.width - 70, 52, 4).fillAndStroke('#EBF3ED', '#88AB75');
doc.fillColor('#0B3B24').fontSize(9).font('Helvetica-Bold').text('EXECUTIVE ENGINEERING SUMMARY & RATIONALE', 43, curY + 6, { lineBreak: false });
doc.fillColor('#234230').fontSize(7.5).font('Helvetica').text(
  'While the original Software Requirements Specification (SRS) defined a foundational baseline focusing on simulated checkout and basic CRUD catalogs, HarvestHub v2.0 has been elevated into an enterprise-grade agricultural ecosystem. The 23 modular enhancements documented below address critical real-world challenges including multi-vendor dispatch isolation, live GPS mapping, multi-modal internal communications, cryptographic OTP security, and localized AI intelligence.',
  43, curY + 18, { width: doc.page.width - 86, align: 'justify', lineGap: 1.2 }
);
doc.restore();

curY += 60;
curY = renderSectionHeader(curY, '9.1 Authentication, Cryptographic Security & Account Recovery');
curY = renderFeatureItem(curY, 'AF-01', 'Dual-Tier Registration with Automated Email OTP Verification', 'Manual sign-ups trigger an automated 6-digit cryptographic, time-limited OTP (SHA-256 hashed) dispatched via custom SMTP gateway. Prevents bot registrations and guarantees validated contact details for authentic transactions.');
curY = renderFeatureItem(curY, 'AF-02', 'Seamless Google & Apple One-Tap Social Authentication', 'Integrated Google Sign-In with OAuth 2.0 and profile image synchronization. Users logging in via Google bypass manual OTP while automatically creating a verified cloud profile in Firestore.');
curY = renderFeatureItem(curY, 'AF-03', 'Self-Service OTP-Based Password Reset & Instant Session Sync', 'Enables users to reset forgotten passwords securely via time-bounded OTP verification. New credentials compute a secure hash locally and sync with Firestore, completely eliminating lockouts.');

curY += 8;
curY = renderSectionHeader(curY, '9.2 Real-Time Geolocation & Interactive Map Ecosystem');
curY = renderFeatureItem(curY, 'AF-04', 'Cross-Role Interactive Real-Time Farmers & Markets Map', 'Integrated Leaflet/GPS map accessible across Customer, Farmer, and Admin panels. Renders live interactive map pins of verified growers, farm gates, roadside stalls, and wholesale mandis.');
curY = renderFeatureItem(curY, 'AF-05', 'Farmer Dynamic Market Pin Drop & Operating Hours Configuration', 'Farmers can pinpoint exact live market coordinates and daily operational hours (e.g., 7:00 AM - 2:00 PM) directly from their portal, updating customer map views instantaneously.');
curY = renderFeatureItem(curY, 'AF-06', 'Hierarchical City/Neighborhood Filtering with 50km GPS Radius', 'Allows buyers to discover growers by Pakistani cities (Karachi, Lahore, Islamabad) and specific sub-areas (Clifton, Gulshan, Malir, North Karachi) with real-time GPS distance calculation within 50 km.');
curY = renderFeatureItem(curY, 'AF-07', '1-Tap Turn-by-Turn GPS Navigation Integration', 'Directly launches native navigation (Google Maps / Apple Maps) from any farmer profile or map pin, providing seamless driving and walking routes directly to the farm.');

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 2
// ══════════════════════════════════════════════════════════════════════════════
renderPageFrame(2, false);

curY = 68;
curY = renderSectionHeader(curY, '9.3 Multi-Vendor Order Splitting & Direct Communication');
curY = renderFeatureItem(curY, 'AF-08', 'Automatic Multi-Vendor Order Splitting Engine', 'When a customer checks out items from multiple distinct farmers in a single cart, the backend automatically partitions the order into isolated sub-orders. Each farmer only receives and fulfills their specific produce.');
curY = renderFeatureItem(curY, 'AF-09', 'Granular Sub-Order Tracking with Direct Cellular Calling (tel:)', 'Customers track individual sub-order statuses per farmer and can initiate 1-tap direct GSM phone calls to the specific farmer for real-time delivery coordination.');
curY = renderFeatureItem(curY, 'AF-10', 'Unified Real-Time Multimedia Communication Suite', 'Built-in 1-on-1 messaging connecting customers and farmers: Real-time text chat with unread counters, push-to-talk voice notes recording/player, camera photo sharing, and voice/video calling interfaces.');

curY += 8;
curY = renderSectionHeader(curY, '9.4 Marketplace Intelligence & Produce Discovery');
curY = renderFeatureItem(curY, 'AF-11', 'Farmer Transparent Marketplace Price Monitor', 'Provides farmers with real-time price monitoring of competing produce across nearby markets, empowering growers to price produce competitively and eliminate predatory middlemen markups.');
curY = renderFeatureItem(curY, 'AF-12', 'Multi-Criteria Dynamic Search & Filtering Matrix', 'High-speed search across Product Name, Category, Farmer Name, Distance slider, Budget-to-Premium price limits, and Farm-Freshness ratings with instant 1-tap filter reset.');
curY = renderFeatureItem(curY, 'AF-13', 'Customer Product Reviews & Multi-Criteria Star Ratings', 'Verified buyers post star ratings and text reviews, automatically recomputing aggregate ratings across both individual products and the farmer’s public profile.');

curY += 8;
curY = renderSectionHeader(curY, '9.5 Logistics, Pickup Scheduling & Inventory Automation');
curY = renderFeatureItem(curY, 'AF-14', 'Farmer Self-Managed Pickup Slot Scheduling Engine', 'Farmers configure customizable pickup windows (e.g. 9:00 AM - 11:00 AM) with slot quotas. Customers select pickup slots at checkout to bypass delivery charges, supported by local offline caching.');
curY = renderFeatureItem(curY, 'AF-15', 'Social Farmer Following & Restock Broadcast Alerts', 'Customers can follow specific farmers. The app triggers automatic in-app alerts and notifications whenever followed farmers harvest fresh crops or restock items.');
curY = renderFeatureItem(curY, 'AF-16', 'Live Inventory Guard & Automated Low-Stock Warnings', 'Real-time stock depletion prevents overselling of zero-stock items while dispatching proactive low-stock warnings (< 10 units) to farmers.');

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 3
// ══════════════════════════════════════════════════════════════════════════════
renderPageFrame(3, false);

curY = 68;
curY = renderSectionHeader(curY, '9.6 Gamification, Loyalty Rewards & Social Proof');
curY = renderFeatureItem(curY, 'AF-17', 'Customer Eco-Loyalty Tier System & Checkout Discounts', 'Tiered loyalty progression (Bronze, Silver, Gold, Eco-Champion) awarding reward points on orders redeemable for instant checkout discounts, paired with a live Customer Leaderboard.');
curY = renderFeatureItem(curY, 'AF-18', 'Farmer Performance & Fulfillment Leaderboard', 'Live competitive ranking of farmers based on delivery fulfillment speed, quality ratings, and transaction volume to motivate top-tier agricultural standards.');

curY += 8;
curY = renderSectionHeader(curY, '9.7 Localization, Artificial Intelligence & Administration');
curY = renderFeatureItem(curY, 'AF-19', 'Native Bilingual Architecture (Urdu & English)', 'Full bilingual implementation supporting native Urdu (ur_PK) and English (en_US) across all screens, metrics, bottom navigation, and dialogs with instant toggle and persistence.');
curY = renderFeatureItem(curY, 'AF-20', 'HarvestAI Botanical & Live Platform Knowledge Assistant', 'Context-aware AI assistant (powered by Gemini API with intelligent local fallback) with real-time knowledge of live farmer counts, cheapest sellers, produce health benefits, and app guides in Urdu & English.');
curY = renderFeatureItem(curY, 'AF-21', 'Admin Real-Time Farmer Verification & Badge Management', 'Administrators inspect grower credentials and toggle verified trust badges (isVerified), displaying the green verification tick across product cards and public profiles.');
curY = renderFeatureItem(curY, 'AF-22', 'Admin Centralized Moderation & Safety Oversight', 'Full administrative transparency over platform-wide message safety, customer dispute moderation, user account suspensions, and live Gross Merchandise Value (GMV) metrics.');
curY = renderFeatureItem(curY, 'AF-23', 'Rich Motion Graphics & Video Hero Card Integration', 'Seamless looping background MP4 video hero banners across Customer, Farmer, and Admin home dashboards for a premium visual experience.');

curY += 10;

// Comparison Table
doc.save();
doc.rect(35, curY, doc.page.width - 70, 15).fill('#0B2B1B');
doc.fillColor('#A1C68A').fontSize(8).font('Helvetica-Bold').text('Summary Comparison: Baseline SRS Scope vs. HarvestHub v2.0 Implemented Reality', 40, curY + 3.5, { lineBreak: false });
doc.restore();

curY += 17;

const tableData = [
  ['Module / Domain', 'Baseline SRS Scope', 'HarvestHub v2.0 Implemented Reality'],
  ['Authentication', 'Basic Email/Password form', 'Email OTP Verification + Google OAuth 2.0 + Instant Password Hash Recovery'],
  ['Location & Map', 'Static text address string', 'Interactive Real-Time Leaflet Map + Pakistan/Karachi Filter + 50km GPS Radius + Navigation'],
  ['Communication', 'Explicitly out of scope', 'Real-time Chat + Push-to-Talk Voice Notes + Camera Photos + Audio/Video Call UI'],
  ['Order Processing', 'Single generic simulated order', 'Automatic Multi-Vendor Order Splitting + Direct Phone Calling to Specific Farmer'],
  ['AI Assistant', 'Basic static FAQ text answers', 'Live Database-Aware Context AI (Gemini + Local Engine) in Urdu, Roman Urdu & English'],
  ['Gamification', 'Not mentioned in SRS', 'Dual Eco-Reward Leaderboards (Customer Discount Points & Farmer Speed Badges)'],
  ['Pickup Scheduling', 'Optional / Basic listing', 'Farmer Self-Managed Slot Scheduling Engine with Quotas & Offline Cache Sync'],
  ['Language Support', 'English only', 'Full Native Bilingual System (Urdu & English) across all screens & dialogs'],
  ['Admin Moderation', 'Standard CRUD table list', 'Live Conversation Monitoring + Verified Farmer Badges + Platform Safety Reports'],
  ['Design Aesthetics', 'Standard mobile templates', 'Premium Dark Emerald Glassmorphic UI with Looping MP4 Video Hero Cards']
];

const colWidths = [78, 148, 300];
const startX = 35;

tableData.forEach((row, i) => {
  const isHeader = i === 0;
  const rowHeight = isHeader ? 13 : 15;

  doc.save();
  doc.rect(startX, curY, doc.page.width - 70, rowHeight).fill(isHeader ? '#1C402B' : (i % 2 === 0 ? '#F4F8F5' : '#FFFFFF'));
  doc.rect(startX, curY, doc.page.width - 70, rowHeight).stroke('#C2D6C8');

  let curX = startX;
  row.forEach((cell, cIdx) => {
    doc.fillColor(isHeader ? '#F0F5F1' : (cIdx === 0 ? '#0E3621' : '#2D4436'))
       .fontSize(isHeader ? 7.2 : 6.3)
       .font(isHeader ? 'Helvetica-Bold' : (cIdx === 0 ? 'Helvetica-Bold' : 'Helvetica'))
       .text(cell, curX + 3, curY + (isHeader ? 3 : 2.5), { width: colWidths[cIdx] - 6, align: 'left', lineBreak: false });
    curX += colWidths[cIdx];
  });
  doc.restore();
  curY += rowHeight;
});

doc.end();
writeStream.on('finish', () => {
  console.log('Flawless 3-page PDF generated at: ' + outputPath);
});
