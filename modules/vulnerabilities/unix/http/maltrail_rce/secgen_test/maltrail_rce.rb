require 'secgen_test/test_helper'

class MaltrailRceTest < SecGenTest
  def test_vulnerability_deployed
    # Check service is running
    assert_service_running('maltrail')

    # Check port is listening
    assert_port_listening(8338)

    # Check vulnerability exists
    response = shell_command("curl -s -X POST http://localhost:8338/login -d 'username=;id&password=test'")
    assert_match(response, /maltrail|root|admin/, "Vulnerability should respond to command injection")
  end
end
