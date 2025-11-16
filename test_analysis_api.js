/**
 * HTTP API test for the intelligent performance analysis framework
 */

import fs from 'fs/promises';

// Load the test user code
const testCode = await fs.readFile('./test_user_code.py', 'utf-8');

const API_BASE = 'http://localhost:3001/api/v1/code_labs';

async function testAnalysisAPI() {
  console.log('🧪 Testing Intelligent Performance Analysis API\n');
  console.log('📝 User Code to Analyze:');
  console.log('-'.repeat(50));
  console.log(testCode);
  console.log('-'.repeat(50));

  try {
    // Test 1: Basic Analysis
    console.log('\n🔍 Testing /analyze endpoint...');
    
    const analysisResponse = await fetch(`${API_BASE}/analyze`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        code: testCode,
        systemDiagram: {
          components: ['web-server', 'url-shortener']
        }
      }),
    });

    if (!analysisResponse.ok) {
      throw new Error(`Analysis failed: ${analysisResponse.statusText}`);
    }

    const analysisData = await analysisResponse.json();
    
    if (!analysisData.success) {
      throw new Error(`Analysis error: ${analysisData.error}`);
    }

    console.log('✅ Analysis endpoint working!');
    console.log('\n📊 Architecture Analysis Results:');
    console.log('Type:', analysisData.analysis.architecture.type);
    console.log('Confidence:', analysisData.analysis.architecture.confidence);
    console.log('Detected Features:', analysisData.analysis.architecture.detectedFeatures);
    
    // Test 2: Educational Insights
    console.log('\n🎓 Educational Insights:');
    analysisData.analysis.insights.forEach((insight, index) => {
      console.log(`${index + 1}. [${insight.type.toUpperCase()}] ${insight.title}`);
      console.log(`   Description: ${insight.description}`);
      console.log(`   Recommendation: ${insight.recommendation || 'None'}`);
      console.log(`   Severity: ${insight.severity}`);
      console.log('');
    });
    
    // Test 3: Recommended Tests
    console.log('🧪 Recommended Test Scenarios:');
    analysisData.analysis.recommendedTests.forEach((test, index) => {
      console.log(`${index + 1}. ${test.name} (${test.testType})`);
      console.log(`   Description: ${test.description}`);
      console.log(`   Parameters:`, test.parameters);
      console.log('');
    });

    // Test 4: Analyze and Test
    console.log('🚀 Testing /analyze-and-test endpoint (baseline only)...');
    
    const analyzeTestResponse = await fetch(`${API_BASE}/analyze-and-test`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        code: testCode,
        systemDiagram: {
          components: ['web-server', 'url-shortener']
        },
        runAllTests: false // Just baseline
      }),
    });

    if (analyzeTestResponse.ok) {
      const analyzeTestData = await analyzeTestResponse.json();
      console.log('✅ Analyze-and-test endpoint working!');
      
      if (analyzeTestData.performanceResults && analyzeTestData.performanceResults.length > 0) {
        console.log('\n🎯 Performance Test Results:');
        analyzeTestData.performanceResults.forEach(result => {
          console.log(`Test: ${result.testName}`);
          console.log(`Success: ${result.success}`);
          if (result.metrics) {
            console.log('Metrics:', result.metrics);
          }
          if (result.error) {
            console.log('Error:', result.error);
          }
          console.log('');
        });
      }
    } else {
      console.log('❌ Analyze-and-test endpoint failed:', analyzeTestResponse.statusText);
    }

    // Verification Summary
    console.log('📋 VERIFICATION SUMMARY:');
    console.log('='.repeat(50));
    
    const expectedChecks = [
      {
        name: 'Architecture Detection (in-memory)',
        passed: analysisData.analysis.architecture.type === 'in-memory',
        actual: analysisData.analysis.architecture.type
      },
      {
        name: 'Detected Global Dictionaries',
        passed: analysisData.analysis.insights.some(i => i.title.includes('Global Dictionary')),
        actual: analysisData.analysis.insights.filter(i => i.title.includes('Global Dictionary')).length
      },
      {
        name: 'Detected datetime.now() Issues',
        passed: analysisData.analysis.insights.some(i => i.title.includes('datetime.now')),
        actual: analysisData.analysis.insights.filter(i => i.title.includes('datetime.now')).length
      },
      {
        name: 'Appropriate Test Selection (memory tests)',
        passed: analysisData.analysis.recommendedTests.some(t => t.testType === 'memory'),
        actual: analysisData.analysis.recommendedTests.map(t => t.testType).join(', ')
      },
      {
        name: 'Educational Value (multiple insights)',
        passed: analysisData.analysis.insights.length >= 2,
        actual: `${analysisData.analysis.insights.length} insights provided`
      },
      {
        name: 'F-string Detection',
        passed: analysisData.analysis.insights.some(i => i.title.includes('F-String')),
        actual: analysisData.analysis.insights.filter(i => i.title.includes('F-String')).length
      }
    ];
    
    expectedChecks.forEach(check => {
      const status = check.passed ? '✅ PASS' : '❌ FAIL';
      console.log(`${status} ${check.name}: ${check.actual}`);
    });
    
    const overallSuccess = expectedChecks.every(check => check.passed);
    console.log('\n🏆 Overall Result:', overallSuccess ? '✅ SUCCESS - Framework working correctly!' : '❌ NEEDS DEBUGGING');
    
    if (!overallSuccess) {
      console.log('\n🔧 Issues found:');
      expectedChecks.filter(check => !check.passed).forEach(check => {
        console.log(`- ${check.name}: Expected different result than "${check.actual}"`);
      });
    } else {
      console.log('\n🎉 The intelligent performance analysis framework is working correctly!');
      console.log('✅ Architecture detection works');
      console.log('✅ Performance issue detection works');
      console.log('✅ Educational insights are generated');
      console.log('✅ Test selection is appropriate');
      console.log('✅ API endpoints are functional');
    }
    
  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
    if (error.stack) console.error('Stack trace:', error.stack);
  }
}

// Run the tests
testAnalysisAPI();