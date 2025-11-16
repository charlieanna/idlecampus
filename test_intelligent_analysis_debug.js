/**
 * Comprehensive test suite for intelligent analysis framework
 * Tests each component and integration points
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

const BASE_URL = 'http://localhost:3001'; // Backend API URL

// Simple fetch implementation using Node.js built-in modules
function fetch(url, options = {}) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const isHttps = parsedUrl.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const reqOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (isHttps ? 443 : 80),
      path: parsedUrl.pathname + parsedUrl.search,
      method: options.method || 'GET',
      headers: options.headers || {}
    };

    const req = client.request(reqOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          ok: res.statusCode >= 200 && res.statusCode < 300,
          status: res.statusCode,
          statusText: res.statusMessage,
          text: () => Promise.resolve(data),
          json: () => Promise.resolve(JSON.parse(data))
        });
      });
    });

    req.on('error', reject);
    
    if (options.body) {
      req.write(options.body);
    }
    
    req.end();
  });
}

// Test data - different Python code patterns
const TEST_CODES = {
  inMemory: `
# In-memory storage implementation
url_storage = {}

def shorten(long_url):
    import random
    import string
    short_code = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
    url_storage[short_code] = long_url
    return short_code

def expand(short_code):
    return url_storage.get(short_code, "URL not found")
`,

  database: `
# Database implementation
import sqlite3
import hashlib

def shorten(long_url):
    conn = sqlite3.connect('urls.db')
    cursor = conn.cursor()
    
    # Create table if not exists
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS urls (
            short_code TEXT PRIMARY KEY,
            long_url TEXT NOT NULL
        )
    ''')
    
    # Generate hash-based short code
    hash_val = hashlib.md5(long_url.encode()).hexdigest()[:8]
    short_code = f"short_{hash_val}"
    
    cursor.execute('INSERT OR IGNORE INTO urls (short_code, long_url) VALUES (?, ?)', 
                   (short_code, long_url))
    conn.commit()
    conn.close()
    return short_code

def expand(short_code):
    conn = sqlite3.connect('urls.db')
    cursor = conn.cursor()
    cursor.execute('SELECT long_url FROM urls WHERE short_code = ?', (short_code,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else "URL not found"
`,

  caching: `
# Redis caching implementation
import redis
import hashlib

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def shorten(long_url):
    hash_val = hashlib.sha256(long_url.encode()).hexdigest()[:8]
    short_code = f"cache_{hash_val}"
    redis_client.setex(short_code, 3600, long_url)  # 1 hour TTL
    return short_code

def expand(short_code):
    long_url = redis_client.get(short_code)
    return long_url.decode() if long_url else "URL not found"
`,

  performance_issues: `
# Code with performance anti-patterns
import datetime
import time

url_storage = {}

def shorten(long_url):
    # Multiple datetime.now() calls - performance anti-pattern
    start_time = datetime.now()
    print(f"Starting at {datetime.now()}")
    
    # Inefficient string concatenation
    short_code = ""
    for i in range(6):
        short_code = short_code + str(i)
    
    # Global dictionary without size limits
    url_storage[short_code] = long_url
    
    # Blocking operation
    time.sleep(0.1)
    
    end_time = datetime.now()
    print(f"Ending at {datetime.now()}")
    
    return short_code

def expand(short_code):
    return url_storage.get(short_code, "URL not found")
`
};

class IntelligentAnalysisDebugger {
  constructor() {
    this.results = {
      backendAPI: {},
      architectureDetection: {},
      educationalInsights: {},
      performanceTests: {},
      endToEndFlow: {}
    };
  }

  async testBackendAPIEndpoints() {
    console.log('\n🔍 Testing Backend API Endpoints...');
    
    const endpoints = [
      { 
        path: '/api/v1/code_labs/analyze',
        method: 'POST',
        data: { code: TEST_CODES.inMemory }
      },
      {
        path: '/api/v1/code_labs/analyze-and-test', 
        method: 'POST',
        data: { 
          code: TEST_CODES.inMemory,
          systemDiagram: { components: ['web-server'] },
          runAllTests: false 
        }
      },
      {
        path: '/api/v1/code_labs/performance-test',
        method: 'POST', 
        data: {
          code: TEST_CODES.inMemory,
          testScenario: {
            name: 'Memory Usage Test',
            testType: 'memory',
            parameters: { dataSize: 100 }
          }
        }
      }
    ];

    for (const endpoint of endpoints) {
      try {
        console.log(`  Testing ${endpoint.path}...`);
        
        const response = await fetch(`${BASE_URL}${endpoint.path}`, {
          method: endpoint.method,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(endpoint.data)
        });

        const responseText = await response.text();
        let data;
        
        try {
          data = JSON.parse(responseText);
        } catch (parseError) {
          throw new Error(`Invalid JSON response: ${responseText}`);
        }

        this.results.backendAPI[endpoint.path] = {
          status: response.status,
          success: response.ok && data.success,
          data: data,
          error: data.error || null
        };

        console.log(`    ✅ ${endpoint.path}: ${response.status} ${data.success ? 'SUCCESS' : 'FAIL'}`);
        
        if (data.error) {
          console.log(`    ⚠️  Error: ${data.error}`);
        }
        
      } catch (error) {
        console.log(`    ❌ ${endpoint.path}: ${error.message}`);
        this.results.backendAPI[endpoint.path] = {
          status: 0,
          success: false,
          error: error.message
        };
      }
    }
  }

  async testArchitectureDetection() {
    console.log('\n🏗️  Testing Architecture Detection...');

    for (const [pattern, code] of Object.entries(TEST_CODES)) {
      try {
        console.log(`  Testing ${pattern} pattern...`);
        
        const response = await fetch(`${BASE_URL}/api/v1/code_labs/analyze`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ code })
        });

        const data = await response.json();
        
        if (data.success) {
          const architecture = data.analysis.architecture;
          console.log(`    ✅ Detected: ${architecture.type} (${Math.round(architecture.confidence * 100)}% confidence)`);
          console.log(`    📊 Features: ${architecture.detectedFeatures.join(', ')}`);
          
          this.results.architectureDetection[pattern] = {
            detectedType: architecture.type,
            confidence: architecture.confidence,
            features: architecture.detectedFeatures,
            success: true
          };
        } else {
          console.log(`    ❌ Analysis failed: ${data.error}`);
          this.results.architectureDetection[pattern] = {
            success: false,
            error: data.error
          };
        }
        
      } catch (error) {
        console.log(`    ❌ ${pattern}: ${error.message}`);
        this.results.architectureDetection[pattern] = {
          success: false,
          error: error.message
        };
      }
    }
  }

  async testEducationalInsights() {
    console.log('\n📚 Testing Educational Insights Generation...');

    try {
      const response = await fetch(`${BASE_URL}/api/v1/code_labs/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          code: TEST_CODES.performance_issues,
          systemDiagram: { 
            components: ['database'],
            architecture: 'single-tier'
          }
        })
      });

      const data = await response.json();
      
      if (data.success) {
        const insights = data.analysis.insights;
        console.log(`    ✅ Generated ${insights.length} insights:`);
        
        insights.forEach((insight, i) => {
          console.log(`      ${i + 1}. [${insight.type.toUpperCase()}] ${insight.title}`);
          console.log(`         Severity: ${insight.severity} | ${insight.description}`);
          if (insight.recommendation) {
            console.log(`         💡 ${insight.recommendation}`);
          }
        });

        this.results.educationalInsights = {
          success: true,
          insightCount: insights.length,
          insightTypes: insights.map(i => i.type),
          severityLevels: insights.map(i => i.severity)
        };
      } else {
        console.log(`    ❌ Insight generation failed: ${data.error}`);
        this.results.educationalInsights = {
          success: false,
          error: data.error
        };
      }
      
    } catch (error) {
      console.log(`    ❌ Insights test failed: ${error.message}`);
      this.results.educationalInsights = {
        success: false,
        error: error.message
      };
    }
  }

  async testPerformanceExecution() {
    console.log('\n⚡ Testing Performance Test Execution...');

    const testScenarios = [
      {
        name: 'Memory Test',
        testType: 'memory',
        parameters: { dataSize: 1000 }
      },
      {
        name: 'Concurrency Test', 
        testType: 'concurrency',
        parameters: { userCount: 10, duration: 5 }
      },
      {
        name: 'Load Test',
        testType: 'load', 
        parameters: { userCount: 5, duration: 10 }
      }
    ];

    for (const scenario of testScenarios) {
      try {
        console.log(`  Testing ${scenario.name}...`);
        
        const response = await fetch(`${BASE_URL}/api/v1/code_labs/performance-test`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            code: TEST_CODES.inMemory,
            testScenario: scenario
          })
        });

        const data = await response.json();
        
        if (data.success && data.testResult) {
          const result = data.testResult;
          console.log(`    ✅ ${scenario.name}: ${result.success ? 'PASSED' : 'FAILED'}`);
          
          if (result.metrics) {
            console.log(`    ⏱️  Execution time: ${result.metrics.execution_time || 'N/A'}s`);
          }
          
          this.results.performanceTests[scenario.name] = {
            success: result.success,
            executionTime: result.metrics?.execution_time || null,
            metrics: result.metrics || null
          };
        } else {
          console.log(`    ❌ ${scenario.name}: ${data.error || 'Test failed'}`);
          this.results.performanceTests[scenario.name] = {
            success: false,
            error: data.error
          };
        }
        
      } catch (error) {
        console.log(`    ❌ ${scenario.name}: ${error.message}`);
        this.results.performanceTests[scenario.name] = {
          success: false,
          error: error.message
        };
      }
    }
  }

  async testEndToEndFlow() {
    console.log('\n🔄 Testing End-to-End Intelligent Analysis Flow...');

    try {
      // Test the complete flow that the frontend uses
      const response = await fetch(`${BASE_URL}/api/v1/code_labs/analyze-and-test`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code: TEST_CODES.inMemory,
          systemDiagram: {
            components: ['web-server', 'url-shortener'],
            architecture: 'single-tier'
          },
          runAllTests: false
        })
      });

      const data = await response.json();
      
      if (data.success) {
        console.log('    ✅ End-to-end flow successful!');
        
        // Check analysis components
        const analysis = data.analysis;
        if (analysis) {
          console.log(`    📊 Architecture: ${analysis.architecture?.type} (${Math.round((analysis.architecture?.confidence || 0) * 100)}%)`);
          console.log(`    💡 Insights: ${analysis.insights?.length || 0} generated`);
          console.log(`    📈 Performance: ${analysis.performanceMetrics?.scalabilityRating || 'N/A'}/10`);
        }

        // Check performance results
        const perfResults = data.performanceResults;
        if (perfResults && perfResults.length > 0) {
          console.log(`    ⚡ Performance tests: ${perfResults.length} executed`);
          perfResults.forEach(result => {
            console.log(`      - ${result.testName}: ${result.success ? 'PASSED' : 'FAILED'}`);
          });
        }

        this.results.endToEndFlow = {
          success: true,
          analysisComplete: !!analysis,
          insightsGenerated: analysis?.insights?.length || 0,
          performanceTestsRun: perfResults?.length || 0,
          architectureDetected: analysis?.architecture?.type || 'unknown'
        };
        
      } else {
        console.log(`    ❌ End-to-end flow failed: ${data.error}`);
        this.results.endToEndFlow = {
          success: false,
          error: data.error
        };
      }
      
    } catch (error) {
      console.log(`    ❌ End-to-end test failed: ${error.message}`);
      this.results.endToEndFlow = {
        success: false,
        error: error.message
      };
    }
  }

  async runAllTests() {
    console.log('🚀 Starting Comprehensive Intelligent Analysis Debug Suite\n');
    
    await this.testBackendAPIEndpoints();
    await this.testArchitectureDetection();  
    await this.testEducationalInsights();
    await this.testPerformanceExecution();
    await this.testEndToEndFlow();
    
    this.generateReport();
  }

  generateReport() {
    console.log('\n📋 COMPREHENSIVE TEST REPORT');
    console.log('=' * 50);

    // Backend API Health
    console.log('\n🔍 Backend API Endpoints:');
    Object.entries(this.results.backendAPI).forEach(([endpoint, result]) => {
      const status = result.success ? '✅ PASS' : '❌ FAIL';
      console.log(`  ${endpoint}: ${status} (${result.status})`);
      if (result.error) {
        console.log(`    Error: ${result.error}`);
      }
    });

    // Architecture Detection
    console.log('\n🏗️ Architecture Detection:');
    Object.entries(this.results.architectureDetection).forEach(([pattern, result]) => {
      if (result.success) {
        console.log(`  ${pattern}: ✅ ${result.detectedType} (${Math.round(result.confidence * 100)}%)`);
      } else {
        console.log(`  ${pattern}: ❌ ${result.error}`);
      }
    });

    // Educational Insights
    console.log('\n📚 Educational Insights:');
    if (this.results.educationalInsights.success) {
      console.log(`  ✅ Generated ${this.results.educationalInsights.insightCount} insights`);
      console.log(`  Types: ${this.results.educationalInsights.insightTypes.join(', ')}`);
    } else {
      console.log(`  ❌ ${this.results.educationalInsights.error}`);
    }

    // Performance Tests
    console.log('\n⚡ Performance Tests:');
    Object.entries(this.results.performanceTests).forEach(([test, result]) => {
      const status = result.success ? '✅ PASS' : '❌ FAIL';
      console.log(`  ${test}: ${status}`);
      if (result.executionTime) {
        console.log(`    Execution time: ${result.executionTime}s`);
      }
    });

    // End-to-End Flow
    console.log('\n🔄 End-to-End Flow:');
    if (this.results.endToEndFlow.success) {
      console.log('  ✅ Complete flow successful');
      console.log(`  Architecture: ${this.results.endToEndFlow.architectureDetected}`);
      console.log(`  Insights: ${this.results.endToEndFlow.insightsGenerated}`);
      console.log(`  Performance tests: ${this.results.endToEndFlow.performanceTestsRun}`);
    } else {
      console.log(`  ❌ ${this.results.endToEndFlow.error}`);
    }

    // Overall Status
    const allTests = [
      ...Object.values(this.results.backendAPI),
      ...Object.values(this.results.architectureDetection),
      this.results.educationalInsights,
      ...Object.values(this.results.performanceTests),
      this.results.endToEndFlow
    ];

    const passedTests = allTests.filter(test => test.success).length;
    const totalTests = allTests.length;
    
    console.log('\n🎯 OVERALL STATUS:');
    console.log(`  ${passedTests}/${totalTests} tests passed (${Math.round(passedTests/totalTests*100)}%)`);
    
    if (passedTests === totalTests) {
      console.log('  🎉 ALL SYSTEMS OPERATIONAL - Ready for production!');
    } else {
      console.log('  ⚠️  Issues detected - See failures above');
    }
  }
}

// Run the tests if this file is executed directly
if (require.main === module) {
  const tester = new IntelligentAnalysisDebugger();
  tester.runAllTests().catch(console.error);
}

module.exports = IntelligentAnalysisDebugger;